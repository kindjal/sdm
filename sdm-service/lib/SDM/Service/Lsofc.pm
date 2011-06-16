package SDM::Service::Lsofc;

use strict;
use warnings;

use SDM;
use IPC::Cmd;
use Data::Dumper;

use JSON;
use LWP::UserAgent;
use HTTP::Request::Common;

$Data::Dumper::Indent = 1;

class SDM::Service::Lsofc {
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

    my $LSOF = IPC::Cmd::can_run("lsof");
    die "lsof not found in PATH" unless ($LSOF);

    # LSOF options
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
        my $records = {};
        my $newrecords = {};
        my $hash;
        while (<KID>) {
            m/^(\w)(.*)$/;
            if ($1 eq 'n') {
                # -- Build a process record of lsof output
                if (scalar keys %$hash == scalar keys %$lsofargs) {
                    # we now have a complete record, remember it in a hash.
                    $hash->{'time'} = time;
                    my $process = delete $hash->{process};
                    if (defined $newrecords->{$process}->{'time'}) {
                        # We've seen this process before. Add to its time seen.
                        my $delta = $hash->{'time'} - $newrecords->{$process}->{'time'};
                        $hash->{'timedelta'} = $newrecords->{$process}->{'timedelta'} + $delta;
                    } else {
                        $hash->{'timedelta'} = 0;
                    }
                    $newrecords->{$process} = $hash;
                }
                # Start a new record.
                $hash = {};
                $hash->{name} = $2;
            }
            while (my ($key,$value) = each %$lsofargs) {
                next if ($key eq 'n'); # n is handled above special
                    $hash->{$value} = $2 if ($1 eq $key);
            }

            if ($1 eq 'm') {
                # -- End of lsof run, report in.
                # We only want to report long running pids
                foreach my $key (keys %$records) {
                    # Remove previously seen pid no longer running
                    if (! defined $newrecords->{$key}) {
                        delete $records->{$key};
                    }
                }
                # Add the new stuff, updating time
                foreach my $key (keys %$newrecords) {
                    my $delta = $newrecords->{$key}->{'timedelta'};
                    if (defined $delta and $delta > $self->report_time) {
                        $records->{$key} = delete $newrecords->{$key};
                    }
                }

                # Report to server at end of record
                my $data = $json->encode($records);
                my $userAgent = LWP::UserAgent->new(agent => __PACKAGE__);
                my $response = $userAgent->request(POST "http://" . $self->host . ":" . $self->port,
                    Content_Type => 'text/xml',
                    Content => $data
                );
                print "" . Data::Dumper::Dumper $response;

                # reset timer
                alarm $self->timeout;
            }
        }
        close(KID) or warn "$LSOF exited $?";
    } else {
        # child execs lsof
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
