
package SDM::Service::Lsofd::Command::Run;

use strict;
use warnings;

use SDM;

use HTTP::Daemon;
use HTTP::Status;
use HTTP::Response;
use Date::Format;
use JSON;

$Data::Dumper::Indent = 1;

class SDM::Service::Lsofd::Command::Run {
    is  => 'SDM::Command::Base',
    has => [
        commit_interval => {
            is    => 'Integer',
            default_value => 10,
            doc   => 'how many seconds between DB commits'
        },
        port => {
            is    => 'Integer',
            default_value => 10001,
            doc   => 'tcp port'
        },
    ],
    has_transient => [
        time_to_commit => {
            is => 'Boolean',
        },
        changes_pending => {
            is => 'Boolean',
        },
        is_processing => {
            is => 'Boolean',
        }
    ],
};

=head2 _process
Iterate over the hash of records indicating hosts/open files and create the
database records via UR objects.  We get a complete record of open files for
a given client host.  So, purge records from the DB that aren't in the current record.
=cut
sub _process {
    my $self = shift;
    my $records = shift;

    # Get the hostname from the first key of first record
    my $firstkey = shift @{ [ keys %$records ] };
    return unless ($firstkey);
    my $hostname = shift @{ [ split("\t",$firstkey) ] };
    return unless ($hostname);

    $self->logger->debug(__PACKAGE__ . " _process $hostname");

    # Remove existing records not just returned in JSON.
    foreach my $existing (SDM::Service::Lsof::Process->get( hostname => $hostname )) {
        my $key = $existing->{hostname} . "\t" . $existing->{pid};
        unless (exists $records->{$key}) {
            $self->logger->debug(__PACKAGE__ . " remove entry $key " . Data::Dumper::Dumper $existing);
            $existing->delete;
        }
    }

    # Enter fresh JSON records.
    foreach my $key (keys %$records) {
        my $record = delete $records->{$key};
        my $pid;
        # Skip /proc files and kernel threads
        #next if ( grep { /^(\/proc|\[.*\])/ } $records->{$key}->{name} );
        if ( grep { /^(\/proc|\[.*\])/ } @{ $records->{$key}->{name} } ) {
            $self->logger->debug("skip proc entry and/or kernel thread");
            next;
        }

        ($hostname,$pid) = split("\t",$key);
        $record->{hostname} = $hostname;
        $record->{pid} = int($pid);

        my $result = SDM::Service::Lsof::Process->get( hostname => $hostname, pid => $pid );
        if ($result) {
            $result->timedelta( $record->{timedelta} );
            $result->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
        } else {
            $self->logger->debug(__PACKAGE__ . " create entry $hostname\t$pid " . $record->{timedelta});
            $record->{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
            $result = SDM::Service::Lsof::Process->create( $record );
        }
    }

    # Determine list of changes
    my @added = grep { $_->__changes__ } $UR::Context::current->all_objects_loaded('SDM::Service::Lsof');
    my @removed = $UR::Context::current->all_objects_loaded('UR::Object::Ghost');
    my @changes = (@added,@removed);
    if (@changes) {
        $self->logger->debug(__PACKAGE__ . " commit " . scalar @changes);
        $self->changes_pending(1);
    }
}

sub _alrm_handler {
    my $self = shift;
    $self->time_to_commit(1);
    alarm $self->commit_interval;
}

sub commit {
    my $self = shift;

    # disconnect from DB to avoid passing handle to child
    SDM::DataSource::Service->disconnect_default_handle();

    # do fork and commit here
    die "cannot fork: $!" unless defined($pid = open(KID));
    if ($pid) {
        # parent unloads objects from memory and returns
        # Unload doesn't work here because some of these objects have changes... so, we have to delete.
        # But delete doesn't remove from memory, turns them to Ghosts.
        # So, what we really want to do to clear memory is to "rollback" then unload the now unchanged objects.
        my @added = grep { $_->__changes__ } $UR::Context::current->all_objects_loaded('SDM::Service::Lsof');
        my @removed = $UR::Context::current->all_objects_loaded('UR::Object::Ghost');
        my @changes = (@added,@removed);

        UR::Context->rollback();
        foreach my $object (@changes) {
            $object->delete();
        }
        $self->changes_pending(0);
        $self->time_to_commit(0);
    } else {
        # child commits DB changes
        UR::Context->commit();
        exit;
    }

}

=head2 execute
Run in daemon mode, receiving HTTP POSTs of JSON data.
=cut
sub execute {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " execute");

    my $d = HTTP::Daemon->new( LocalPort => $self->port, ReuseAddr => 1 ) or die "failed to create new http daemon: $!";

    $self->logger->info("Listening, contact me at: <URL:", $d->url, ">");

    $self->logger->debug("commit interval: " . $self->commit_interval);
    alarm $self->commit_interval;

    $SIG{'ALRM'} = sub { $self->_alrm_handler };

    while (1) {

        my $conn = eval { $d->accept; };
        if ($@ and $! =~ /Interrupted system call/ and $self->time_to_commit and $self->changes_pending) {
            # commit code goes here
            $self->commit();

        } elsif ($@) {
            # unexpected errors
            die "error during accept(): $@";
        }
        next unless ($conn);

        # If we have changes pending and we haven't committed for a while because
        # we are really busy, we need to take measures to commit.

        $self->is_processing(1);
        while (my $r = $conn->get_request) {
            if ($r->method eq 'POST') {
                # FIXME: Decode JSON data and store in Database table
                my $json = JSON->new;
                my $data = $json->decode($r->content);
                $self->_process($data);
                $conn->send_response( HTTP::Response->new( 200, "OK" ) );
            } else {
                $conn->send_error(RC_FORBIDDEN, "Unsupported method: " . $r->method)
            }
        }
        $conn->close;
        undef($conn);
        $self->is_processing(0);
    }

    return 1;
}

sub help_brief {
    return 'launch lsof daemon';
}

1;
