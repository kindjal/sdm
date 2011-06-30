#!/usr/bin/perl

package SDM::Service::WebApp::Lsof;

use strict;
use warnings;

use Web::Simple 'SDM::Service::WebApp::Lsof';

$Data::Dumper::Indent = 1;

our $loaded = 0;
sub load_modules {
    return if $loaded;
    eval "
        use SDM;
        use JSON;
    ";
    if ($@) {
        die "failed to load required modules: $@";
    }

    # search's callbacks are expensive, web server can't change anything anyway so don't waste the time
    SDM::Search->unregister_callbacks('UR::Object');
    $loaded = 1;
}

=head2 process
Iterate over the hash of records indicating hosts/open files and create the
database records via UR objects.  We get a complete record of open files for
a given client host.  So, purge records from the DB that aren't in the current record.
=cut

sub process {
    my $self = shift;
    my $content = shift;
    my $json = JSON->new;
    my $records = $json->decode($content);

    # Get the hostname from the first key of first record
    my $firstkey = shift @{ [ keys %$records ] };
    return unless ($firstkey);
    my $hostname = shift @{ [ split("\t",$firstkey) ] };
    return unless ($hostname);

    # Remove existing records not just returned in JSON.
    foreach my $existing (SDM::Service::Lsof::Process->get( hostname => $hostname )) {
        my $key = $existing->{hostname} . "\t" . $existing->{pid};
        $existing->delete unless (exists $records->{$key});
    }
    # Remove files that now have no process.

    # Enter fresh JSON records.
    foreach my $key (keys %$records) {
        my $record = delete $records->{$key};
        my $pid;
        # Skip /proc files and kernel threads
        next if ( grep { /^(\/proc|\[.*\])/ } @{ $records->{$key}->{name} } );

        ($hostname,$pid) = split("\t",$key);
        $record->{hostname} = $hostname;
        $record->{pid} = int($pid);

        my $process = SDM::Service::Lsof::Process->get( hostname => $hostname, pid => $pid );
        if ($process) {
            $process->update($record);
        } else {
            $record->{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
            $process = SDM::Service::Lsof::Process->create( $record );
            unless ($process) {
                die "failed to create new process record";
            }
        }
    }

    # Determine list of changes
    my @added = grep { $_->__changes__ } $UR::Context::current->all_objects_loaded('SDM::Service::Lsof::Process');
    my @removed = $UR::Context::current->all_objects_loaded('UR::Object::Ghost');
    my @changes = (@added,@removed);
    if (@changes) {
        UR::Context->commit();
    }

    return scalar @changes;
}

dispatch {

    sub (POST + /service/lsof + %*) {
        my $self = shift;
        my ($params) = @_;
        my $msg;

        load_modules();

        eval {
            my $count = $self->process($params->{data});
            $msg = "OK: $count changes";
        };
        if ($@) {
            $msg = __PACKAGE__ . " Error in process: $@";
        }

        return [
            200,
            ['Content-type', 'text/plain'],
            [$msg]
        ];
    },
};

SDM::Service::WebApp::Lsof->run_if_script;
