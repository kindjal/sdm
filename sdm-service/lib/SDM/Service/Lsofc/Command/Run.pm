
package SDM::Service::Lsofc::Command::Run;

use strict;
use warnings;

use SDM;
use IPC::Cmd;
use Data::Dumper;

use JSON;
use LWP::UserAgent;
use HTTP::Request::Common;
use Sys::Hostname;

$Data::Dumper::Indent = 1;

class SDM::Service::Lsofc::Command::Run {
    is  => 'SDM::Command::Base',
    has => [
        url => {
            is    => 'Text',
            default_value => 'http://localhost:8090/server/lsof',
            doc   => 'lsofd server URL',
        },
        wait => {
            # Wait this many seconds between lsof calls.
            # In production maybe this is every minute or 5 minutes.
            is    => 'Number',
            default_value => 300,
            doc   => 'seconds to wait between lsof runs'
        },
        timeout => {
            # Wait this long for lsof to report back before dying.
            # Needs to be longer than wait.
            is    => 'Number',
            default_value => 310,
            doc   => 'seconds to wait for lsof before dying'
        },
    ],
    has_transient_optional => [
        userAgent => {
            is => 'LWP::UserAgent',
        }
    ]
};

sub error {
    # An error method to logger msg + exit 1
    # Better than die because we log in init/upstart script
    my $self = shift;
    my $msg = shift;
    $self->logger->error(__PACKAGE__ . " $msg");
    exit 1;
}

sub post {
    my $self = shift;
    my (%param) = @_;
    my $records = $param{records};
    my $msg = $param{msg};

    # POST to server at end of record
    my $data = {};
    my $hostname = Sys::Hostname::hostname;
    if ($msg) {
        # Here there was a problem, and we're telling URL what
        # the problem is so it's visible on that server.
        $data->{$hostname} = $msg;
    } else {
        $data->{$hostname} = $records;
    }

    my $json = JSON->new;
    my $jsondata = $json->encode($data);
    my $size = length($jsondata);
    my $response = $self->userAgent->request(POST $self->url,
        Content_Type => 'application/x-www-form-urlencoded',
        Content_Length => $size,
        Content => "data=$jsondata"
    );

    my $count = $#{ [ keys %$records ] } + 1;
    $self->logger->info(__PACKAGE__ . " POST: $count records to " . $self->url);
    $self->logger->debug(__PACKAGE__ . " POST:  " . $jsondata);

    if ($response->code != 200) {
        $self->logger->warn(__PACKAGE__ . " server responds:  " . $response->code . " " . $response->message);
    } else {
        $self->logger->debug(__PACKAGE__ . " server responds:  " . $response->code . " " . $response->content);
    }

    return;
}

sub execute {
    my $self = shift;
    $self->logger->info(__PACKAGE__ . " execute");

    my $LSOF = IPC::Cmd::can_run("lsof");
    my $MOUNT = IPC::Cmd::can_run("mount");
    $self->error("lsof not found in PATH") unless ($LSOF);
    $self->error("mount not found in PATH") unless ($MOUNT);
    $self->error("'timeout' attribute must be longer than 'wait' attribute") if ($self->timeout <= $self->wait);

    # lsof options, anything here must be expected by the server and
    # supported by the DB schema.
    my $lsofargs = {
        n => 'name',
        p => 'pid',
        g => 'pgid',
        c => 'command',
        L => 'username',
        u => 'uid',
    };
    my $hostmap = {};

    $| = 1;

    my @options = ("-t","nfs");
    my @args = ();
    my $pid;

    $self->error("cannot fork: $!") unless defined($pid = open(KID, "-|"));
    $SIG{ALRM} = sub { $self->error("$MOUNT pipe broke: $!") };
    if ($pid) {
        # parent
        my $host;
        my $ip;
        while (<KID>) {
            # ntap11:/vol/appsrv-dev on /mnt/appsrv-dev type nfs (rw,bg,intr,tcp,rsize=32768,wsize=32768,addr=10.0.28.46)
            m/^(\S+):.*addr=((\d+)(\.\d+){3})/;
            if ($1 and $2) {
                $host = $1;
                $ip = $2;
                $self->logger->debug(__PACKAGE__ . " mount reports $host at $ip");
                $hostmap->{$host} = $ip;
            }
        }
        close(KID);
    } else {
        # child execs mount
        my $cmd = join(" ",$MOUNT,@args);
        $self->logger->debug(__PACKAGE__ . " child executes mount: $cmd");
        exec($MOUNT, @options, @args) or $self->error("can't exec program: $!");
        # exec never returns unless an error in exec();
        $self->error("failed to exec: $!");
    }

    @options = ("-r" . $self->wait,"-N","-F",join('',keys %$lsofargs) );
    @args = ();

    # This userAgent posts to url, either sending lsof results, or an error message.
    my $lwp = LWP::UserAgent->new(agent => __PACKAGE__);
    $self->userAgent($lwp);

    $self->error("cannot fork: $!") unless defined($pid = open(KID, "-|"));
    $SIG{ALRM} = sub { $self->post(msg => "$LSOF pipe broke: $!") };
    if ($pid) {
        # parent
        # records are reported to the server
        my $records = {};
        # lsofrecords is the clients way to keep tabs on things
        my $lsofrecords = {};
        my $hash;
        while (<KID>) {
            m/^(\w)(.*)$/;
            if ($1 eq 'p') {
                # -- Build a process record of lsof open file item
                # This record is keyed on PID of process with file open + hostname.
                if (scalar keys %$hash) {
                    # We matched on "p" and hash is not empty, so record it in lsofrecords.
                    my $pid = delete $hash->{pid};
                    my $key = Sys::Hostname::hostname() . "\t" . $pid;
                    $lsofrecords->{$key} = $hash;
                }
                # Start a new record with the pid.
                $hash = {};
                $hash->{'pid'} = $2;
                # Name must be a list, a list of filenames open
                $hash->{'name'} = [];
            }
            while (my ($key,$value) = each %$lsofargs) {
                next if ($key eq 'p'); # p is handled above special
                if ($1 eq $key) {
                    # This is an lsof element that we are prepared to store.
                    if ($value eq 'name') {
                        # Look in the hostmap for the IP of the nfs server.
                        # /gscuser/mcallawa/git/SDM (nfs10home:/vol/home/ebecker)
                        my $name = $2;
                        $name =~ /^.*\((\S+):(\S+)\)$/;
                        if ($1 and $hostmap->{$1}) {
                            $hash->{'nfsd'} = $hostmap->{$1};
                        }
                        push @{ $hash->{$value} }, $name;
                    } else {
                        $hash->{$value} = $2;
                    }
                }
            }

            if ($1 eq 'm') {
                # -- End of lsof run, report in to server.
                # We only want to report long running pids
                my $count = 0;
                foreach my $key (keys %$records) {
                    # Remove previously seen pid no longer running
                    if (! exists $lsofrecords->{$key}) {
                        #$self->logger->debug(__PACKAGE__ . " Remove " . $key);
                        delete $records->{$key};
                        $count++;
                    }
                }
                $self->logger->debug(__PACKAGE__ . " Removed $count pids from memory") if ($count);

                $count = 0;
                foreach my $key (keys %$lsofrecords) {
                    if (grep { /^(\/proc|\[)/ } @{ $lsofrecords->{$key}->{name} } ) {
                        #$self->logger->debug(__PACKAGE__ . " skipping " . Data::Dumper::Dumper $lsofrecords->{$key}->{name});
                        next;
                    }
                    #$self->logger->debug(__PACKAGE__ . " Add " . Data::Dumper::Dumper $key);
                    $records->{$key} = $lsofrecords->{$key};
                    $count++;
                }
                $lsofrecords = {};

                $self->logger->debug(__PACKAGE__ . " Tracking $count pids in memory") if ($count);

                $self->post( records => $records );

                alarm $self->timeout;
            }
        }
        close(KID) or $self->logger->warning(__PACKAGE__ . " $LSOF exited: $?");
    } else {
        # child execs lsof
        my $cmd = join(" ",$LSOF,@options,@args);
        $self->logger->debug(__PACKAGE__ . " child executes lsof: $cmd");
        exec($LSOF, @options, @args) or $self->error("can't exec program: $!");
        # exec never returns unless an error in exec();
        $self->error("failed to exec: $!");
    }

    $self->logger->info(__PACKAGE__ . " end of execute");
    return 1;
}

sub help_brief {
    return 'launch lsof agent';
}

1;
