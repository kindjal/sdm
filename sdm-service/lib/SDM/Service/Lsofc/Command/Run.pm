
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
            default_value => 5,
            doc   => 'seconds to wait between lsof runs'
        },
        timeout => {
            # Wait this long for lsof to report back before dying.
            is    => 'Number',
            default_value => 15,
            doc   => 'seconds to wait for lsof before dying'
        },
    ],
};

sub execute {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " execute");

    my $LSOF = IPC::Cmd::can_run("lsof");
    my $MOUNT = IPC::Cmd::can_run("mount");
    die "lsof not found in PATH" unless ($LSOF);
    die "mount not found in PATH" unless ($MOUNT);

    # lsof options, anything here must be expected by the server and
    # supported by the DB schema.
    my $lsofargs = {
        n => 'name',
        p => 'process',
        c => 'command',
        L => 'username',
        u => 'uid',
    };
    my $hostmap = {};

    $| = 1;

    my @options = ("-t","nfs");
    my @args = ();
    my $pid;

    die "cannot fork: $!" unless defined($pid = open(KID, "-|"));
    $SIG{ALRM} = sub { die "$MOUNT pipe broke" };
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
        exec($MOUNT, @options, @args) or die "can't exec program: $!";
        # exec never returns unless an error in exec();
        die "failed to exec: $!";
    }

    @options = ("-r" . $self->wait,"-N","-F",join('',keys %$lsofargs) );
    @args = ();

    die "cannot fork: $!" unless defined($pid = open(KID, "-|"));
    $SIG{ALRM} = sub { die "$LSOF pipe broke" };
    if ($pid) {
        # parent
        my $json = JSON->new;
        # records are reported to the server
        my $records = {};
        # lsofrecords is the clients way to keep tabs on things
        my $lsofrecords = {};
        my $hash;
        while (<KID>) {
            m/^(\w)(.*)$/;
            if ($1 eq 'p') {
                # -- Build a process/pid record of lsof open file item
                # This record is keyed on PID of process with file open + hostname.
                if (scalar keys %$hash) {
                    # We matched on "p" and hash is not empty, so record it in lsofrecords.
                    my $process = delete $hash->{process};
                    my $key = Sys::Hostname::hostname() . "\t" . $process;
                    $lsofrecords->{$key} = $hash;
                }
                # Start a new record with the pid.
                $hash = {};
                $hash->{'process'} = $2;
                # Name must be a list
                $hash->{'name'} = [];
            }
            while (my ($key,$value) = each %$lsofargs) {
                next if ($key eq 'p'); # p is handled above special
                if ($1 eq $key) {
                    # This is an lsof element that we are prepared to store.
                    if ($value eq 'name') {
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
                        #$self->logger->debug("Remove " . $key);
                        delete $records->{$key};
                        $count++;
                    }
                }
                $self->logger->debug("Removed $count pids from memory") if ($count);

                $count = 0;
                foreach my $key (keys %$lsofrecords) {
                    if (grep { /^(\/proc|\[)/ } @{ $lsofrecords->{$key}->{name} } ) {
                        #$self->logger->debug("skipping " . Data::Dumper::Dumper $lsofrecords->{$key}->{name});
                        next;
                    }
                    #$self->logger->debug("Add " . Data::Dumper::Dumper $key);
                    $records->{$key} = $lsofrecords->{$key};
                    $count++;
                }
                $lsofrecords = {};

                $self->logger->debug("Tracking $count pids in memory") if ($count);

                # POST to server at end of record
                my $data = $json->encode($records);
                my $userAgent = LWP::UserAgent->new(agent => __PACKAGE__);
                my $size = length($data);
                my $response = $userAgent->request(POST $self->url,
                    Content_Type => 'application/x-www-form-urlencoded',
                    Content_Length => $size,
                    Content => "data=$data"
                );
                $self->logger->debug("POST:  " . $data);
                if ($response->code != 200) {
                    $self->logger->debug("server responds:  " . $response->code . " " . $response->message);
                } else {
                    $self->logger->debug("server responds:  " . $response->code . " " . $response->content);
                }

                alarm $self->timeout;
            }
        }
        close(KID) or warn "$LSOF exited $?";
    } else {
        # child execs lsof
        my $cmd = join(" ",$LSOF,@options,@args);
        $self->logger->debug(__PACKAGE__ . " child executes lsof: $cmd");
        exec($LSOF, @options, @args) or die "can't exec program: $!";
        # exec never returns unless an error in exec();
        die "failed to exec: $!";
    }

    return 1;
}

sub help_brief {
    return 'launch lsof agent';
}

1;
