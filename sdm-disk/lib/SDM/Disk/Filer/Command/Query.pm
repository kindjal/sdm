
package SDM::Disk::Filer::Command::Query;

use strict;
use warnings;
use feature 'switch';

use SDM;

# Usage function
use Pod::Find qw(pod_where);
use Pod::Usage;

# Autoflush
local $| = 1;

class SDM::Disk::Filer::Command::Query {
    is => 'SDM::Command::Base',
    has_optional => [
        filername => {
            # If I use is => Filer here, UR errors out immediately if the filer doesn't exist.
            # If I use is => Text, then I can use get_or_create to add on the fly, or query them all.
            #is => 'SDM::Disk::Filer',
            is => 'Text',
            doc => 'Query the named filer',
        },
        force => {
            is => 'Boolean',
            default => 0,
            doc => 'Query all filers regardless of status',
        },
        allow_mount => {
            is => 'Boolean',
            default => 0,
            doc => 'Allow mounting of filesystems to discover disk groups',
        },
        mount_path_rule => {
            is => 'Text',
            default_value => '^(/vol/aggr0|/vol):/gscmnt',
            doc => 'Colon separated rule to translate physical_path to mount_path.  Used with discover_volumes. eg: /vol:/gscmnt'
        },
        translate_path => {
            is => 'Boolean',
            default => 0,
            doc => 'Map physical_path /vol/homeXYZ to volume name XYZ, this is an old convention',
        },
        timeout => {
            is => 'Number',
            default => 15,
            doc => 'Not yet implemented',
        },
        host_maxage => {
            is => 'Number',
            default => 86400,
            doc => 'max seconds since last check',
        },
        vol_maxage => {
            is => 'Number',
            default => 15,
            doc => 'max days until volume is considered purgable',
        },
        rrdpath => {
            is => 'Text',
            default => $ENV{SDM_DISK_RRDPATH} ||= "/var/cache/sdm/rrd",
            doc => 'Path to rrd file storage (not yet implemented)',
        },
        purge => {
            is => 'Boolean',
            default => 0,
            doc => 'Purge aged volume entries (not yet implemented)',
        },
        cleanonly => {
            is => 'Boolean',
            default => 0,
            doc => 'Remove volumes from the DB that the Filer no longer exports',
        },
        discover_groups => {
            is => 'Boolean',
            default => 0,
            doc => 'Discover disk groups from touch files on volumes and create them on the fly',
        },
        discover_volumes => {
            is => 'Boolean',
            default => 0,
            doc => 'Create volumes based on what we discover, otherwise only update volumes already defined',
        },
        is_current => {
            is => 'Boolean',
            default => 0,
            doc => 'Check currency status',
        },
    ],
    doc => 'Queries volume usage of GPFS filer',
};

sub help_brief {
    return 'Updates volume usage information for filer';
}

sub help_synopsis {
    return <<EOS
Updates volume usage information for filer
EOS
}

sub help_detail {
    return <<EOS
Updates volume usage information for filer
EOS
}

=head2 validate_volumes
Iterate over all Volumes associated with this Filer, check is_current() and warn on all stale volumes.
NB. This isn't used or exposed yet, not sure if this is the right place to do this.
=cut
sub _validate_volumes {
    my $self = shift;
    $self->logger->error(__PACKAGE__ . " max age has not been specified\n")
        if (! defined $self->vol_maxage);
    $self->logger->error(__PACKAGE__ . " max age makes no sense: $self->vol_maxage\n")
        if ($self->vol_maxage < 0 or $self->vol_maxage !~ /\d+/);

    foreach my $volume (SDM::Disk::Volume->get( filername => $self->name )) {
        $volume->validate($self->vol_maxage);
    }
}

=head2 purge_volumes
Iterate over all Volumes associated with this Filer, check is_current() and purge all stale volumes.
NB. This isn't used or exposed yet, not sure if this is the right place to do this.
=cut
sub _purge_volumes {
    my $self = shift;
    $self->logger->error(__PACKAGE__ . " max age has not been specified\n")
        if (! defined $self->vol_maxage);
    $self->logger->error(__PACKAGE__ . " max age makes no sense: $self->vol_maxage\n")
        if ($self->vol_maxage < 0 or $self->vol_maxage !~ /\d+/);

    foreach my $volume (SDM::Disk::Volume->get( filername => $self->name )) {
        $volume->purge($self->vol_maxage);
    }
}

=head2 _query
Query the master host of a filer and update volume data.
=cut
sub _query {
    my $self = shift;
    my $filer = shift;

    if ($filer->duplicates) {
        $self->logger->error(__PACKAGE__ . " filer " . $filer->name . " duplicates " . $filer->duplicates . " query it instead");
        return;
    }

    # Just check if Filer is_current
    $self->logger->warn(__PACKAGE__ . " running query on filer " . $filer->name);
    if ($self->is_current) {
        if ($filer->is_current($self->host_maxage)) {
            $self->logger->warn(__PACKAGE__ . " filer " . $filer->name . " is current");
        } else {
            $self->logger->warn(__PACKAGE__ . " filer " . $filer->name . " is NOT current, last check: " . $filer->last_modified);
        }
        next;
    }

    eval {
        my @params = ( loglevel => $self->loglevel );
        push @params, ( allow_mount => $self->allow_mount ) if ($self->discover_groups);
        push @params, ( translate_path => $self->translate_path );
        push @params, ( discover_volumes => $self->discover_volumes );
        push @params, ( discover_groups => $self->discover_groups );
        push @params, ( mount_path_rule => $self->mount_path_rule );
        push @params, ( filer => $filer );

        my $obj;
        given ($filer->type) {
            when ('gpfs') {
                $obj = SDM::Disk::Filer::Command::Query::GpfsDiskUsage->create( @params );
            }
            default {
                $obj = SDM::Disk::Filer::Command::Query::SnmpDiskUsage->create( @params );
            }
        }

        unless ($obj) {
            $self->logger->error(__PACKAGE__ . " unable to query filer " . $filer->name);
            return;
        }

        $obj->acquire_volume_data();
        $obj->delete;
    };
    if ($@) {
        # log here, but not high priority, it's common
        $self->logger->warn(__PACKAGE__ . " error with query: $@");
        $filer->status(0);
    }
    return 1;
}

=head2 execute
Execute queries on a named Filer and stores disk usage information.
=cut
sub execute {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " execute");

    my @filers;
    if ($self->filername) {
        my $filer = SDM::Disk::Filer->get_or_create( name => $self->filername );
        unless ($filer) {
            $self->logger->error(__PACKAGE__ . " failed to get or create '" . $self->filername . "'");
            return;
        }
        push @filers, $filer;
    }

    # If not given on the CLI, ask the DB about filers we know about.
    unless (@filers) {
        if ($self->force) {
            # If "force", get all Filers and query them even if status is 0.
            @filers = SDM::Disk::Filer->get();
        } else {
            # Query all filers that have status => 1...
            # This is what we use for a cron job.
            @filers = SDM::Disk::Filer->get( status => 1 );
        }
    }

    unless (@filers) {
        $self->logger->warn(__PACKAGE__ . " no filers to be scanned. Add filers with 'add'.");
    }

    # Otherwise, query existing filers for update
    foreach my $filer (@filers) {
        $self->_query( $filer );
    }

    UR::Context->commit();

    # Now update disk group RRD files.
    my $rrd = SDM::Utility::DiskGroupRRD->create( loglevel => $self->loglevel );
    $rrd->run();

    return 1;
}

1;
