
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
        host => {
            is    => 'Text',
            default_value => 'localhost',
            doc   => 'lsofd server host',
        },
        port => {
            is    => 'Number',
            default_value => 10001,
            doc   => 'lsofd server port',
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
            doc   => 'seconds to wait for lsof to update'
        },
        report_time => {
            # If we see a process running for longer than this many seconds,
            # report it to the home server.
            # In production maybe this is five minutes (300 sec) or something.
            is    => 'Number',
            default_value => 10,
            doc   => 'seconds a process must be running before being reported to server'
        },
    ],
};

sub execute {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " execute");

    my $LSOF = IPC::Cmd::can_run("lsof");
    die "lsof not found in PATH" unless ($LSOF);

    # lsof options, anything here must be expected by the server and
    # supported by the DB schema.
    my $lsofargs = {
        n => 'name',
        p => 'process',
        c => 'command',
        L => 'user',
        u => 'uid',
    };

    my @options = ("-r" . $self->wait,"-N","-F",join('',keys %$lsofargs) );
    my @args = ();
    my $pid;

    $| = 1;

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
                if (scalar keys %$hash == scalar keys %$lsofargs) {
                    # we now have a complete record, remember it in a hash.
                    my $process = delete $hash->{process};
                    my $key = Sys::Hostname::hostname() . "\t" . $process;

                    if (defined $lsofrecords->{$key}) {
                        # We've seen this process before. Add to its time seen.
                        $hash->{'time'} = $lsofrecords->{$key}->{'time'};
                        my $delta = time - $lsofrecords->{$key}->{'time'};
                        $hash->{'timedelta'} = $lsofrecords->{$key}->{'timedelta'} + $delta;
                    } else {
                        $hash->{'time'} = time;
                        $hash->{'timedelta'} = 0;
                    }
                    $lsofrecords->{$key} = $hash;
                }
                # Start a new record.
                $hash = {};
                $hash->{process} = $2;
            }
            while (my ($key,$value) = each %$lsofargs) {
                next if ($key eq 'p'); # p is handled above special
                if ($1 eq $key) {
                    if (defined $hash->{$value}) {
                        # Some items occur more than once.
                        my $item = $hash->{$value};
                        $hash->{$value} = [$item];
                        push @{ $hash->{$value} }, $2;
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
                        delete $records->{$key};
                        $count++;
                    }
                }
                $self->logger->debug("Removed $count pids from memory") if ($count);

                # Add the new stuff, updating time
                $count = 0;
                foreach my $key (keys %$lsofrecords) {
                    next if ($lsofrecords->{$key}->{name} =~ /^(\/proc|\[)/); # skip proc and kernel entries
                    my $delta = $lsofrecords->{$key}->{'timedelta'};
                    if (defined $delta and $delta > $self->report_time) {
                        $records->{$key} = $lsofrecords->{$key};
                        $count++;
                    }
                }
                $self->logger->debug("Tracking $count pids in memory") if ($count);

                # Report to server at end of record
                my $data = $json->encode($records);
                my $userAgent = LWP::UserAgent->new(agent => __PACKAGE__);
                my $response = $userAgent->request(POST "http://" . $self->host . ":" . $self->port,
                    Content_Type => 'text/json',
                    Content => $data
                );
                #$self->logger->debug("send:  " . $data);
                $self->logger->debug("server responds:  " . $response->code);
                if ($response->code != 200) {
                    $self->logger->error("server response with error:\n" . Data::Dumper::Dumper $response);
                }

                # reset timer
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
