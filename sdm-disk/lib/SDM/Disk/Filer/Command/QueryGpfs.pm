
package SDM::Disk::Filer::Command::QueryGpfs;

use strict;
use warnings;

use SDM;

# Checking currentness in host_is_current()
use Date::Manip;
use Date::Manip::Date;

# Usage function
use Pod::Find qw(pod_where);
use Pod::Usage;

use File::Basename qw(basename);

# Autoflush
local $| = 1;

class SDM::Disk::Filer::Command::QueryGpfs {
    is => 'SDM::Command::Base',
    has_optional => [
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
        mount_point => {
            is => 'Text',
            default => '/gscmnt',
            doc => 'Specify the mount_point used by autofs to access volumes, this is used with --discover_volumes',
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
        filername => {
            # If I use is => Filer here, UR errors out immediately if the filer doesn't exist.
            # If I use is => Text, then I can use get_or_create to add on the fly, or query them all.
            #is => 'SDM::Disk::Filer',
            is => 'Text',
            doc => 'Query the named filer',
        },
        physical_path => {
            is => 'Text',
            doc => 'Query the named filer for this export',
        },
        query_paths => {
            is => 'Boolean',
            doc => 'Query the named filer for exports, but not usage',
        },
    ],
    doc => 'Queries volume usage of GPFS filer',
};

sub help_brief {
    return 'Updates volume usage information';
}

sub help_synopsis {
    return <<EOS
Updates volume usage information
EOS
}

sub help_detail {
    return <<EOS
Updates volume usage information
EOS
}

=head2 update_volumes
Update data for all Volumes associated with this Filer.
=cut
sub update_volumes {
    my $self = shift;
    my $volumedata = shift;
    # volumedata is a hash that looks like this:
    # volumedata: {
    #     'aggr0' => {
    #                       'disk_group' => undef,
    #                       'total_kb' => '11603570688',
    #                       'mount_path' => '/gscmnt/aggr0',
    #                       'name' => 'aggr0',
    #                       'used_kb' => 93415936,
    #                       'physical_path' => '/vol/aggr0'
    #                       'filesets' => [ ... ],
    #                       '...LUN...' => [ ... ],
    #                     }
    #   }
    my $filername = shift;

    unless ($filername) {
        $self->logger->error(__PACKAGE__ . " update_volumes(): no filer given");
        return;
    }
    unless ($volumedata) {
        $self->logger->warn(__PACKAGE__ . " update_volumes(): filer " . $filername . " returned empty volumedata");
        return;
    }

    $self->logger->warn(__PACKAGE__ . " update_volumes($filername)");

    unless ($self->physical_path) {
        # QueryGpfs First find and remove volumes in the DB that are not detected on this filer
        # For this filer, find any stored volumes that aren't present in the volumedata.
        # Note that we skip this step if we specified a single physical_path to update.
        foreach my $volume ( SDM::Disk::Volume->get( filername => $filername ) ) {
            foreach my $path ($volume->physical_path) {
                next unless($path);
                $path =~ s/\//\\\//g;
                if ( ! grep /$path/, keys %$volumedata ) {
                    $self->logger->warn(__PACKAGE__ . " volume is no longer exported by filer '$filername': " . $volume->id);
                    # FIXME: do we want to auto-remove like this?
                    #$volume->delete;
                }
            }
        }
        return 1 if ($self->cleanonly);
    }

    foreach my $name (keys %$volumedata) {

        my $physical_path = $volumedata->{$name}->{physical_path};

        my $volume = SDM::Disk::Volume->get_or_create( filername => $filername, physical_path => $physical_path, name => $name );
        unless ($volume) {
            $self->logger->error(__PACKAGE__ . " failed to get_or_create volume: $filername, $physical_path, $name");
            next;
        }
        $self->logger->debug(__PACKAGE__ . " found volume: $name: $filername, $physical_path");

        foreach my $fileset (@{ $volumedata->{$name}->{filesets} }) {
            my @keys = ('name','type','kb_size','kb_quota','kb_limit','kb_in_doubt','kb_grace','files','file_quota','file_limit','file_in_doubt','file_grace','file_entryType','parent_volume_name');
            my %params;
            @params{@keys} = @$fileset;
            $params{parent_volume_name} = $name;
            $params{filername} = $filername;
            $params{physical_path} = $volumedata->{$name}->{physical_path} . "/" . $name;

            my $fs = SDM::Disk::Fileset->get_or_create( %params );
            unless ($fs) {
                $self->logger->error(__PACKAGE__ . " failed to get_or_create fileset: $name");
                next;
            }
            $self->logger->debug(__PACKAGE__ . " found fileset: $name");
        }

        # Ensure we have the Group before we update this attribute of a Volume
        my $group_name = $volumedata->{$name}->{disk_group};
        if ($group_name) {
            my $group;
            if ($self->discover_groups) {
                $group = SDM::Disk::Group->get_or_create( name => $volumedata->{$name}->{disk_group} );
            } else {
                $group = SDM::Disk::Group->get( name => $volumedata->{$name}->{disk_group} );
            }
            unless ($group) {
                $self->logger->error(__PACKAGE__ . " ignoring currently unknown disk group: $group_name");
                next;
            }
        } else {
            $self->logger->warn(__PACKAGE__ . " no group found for volume: $name");
        }

        unless ($volume) {
            $self->logger->error(__PACKAGE__ . " failed to get_or_create volume: $name");
            next;
        }

        # FIXME: do same with filesets? or do this like filesets above?
        foreach my $attr (keys %{ $volumedata->{$name} }) {
            next unless (defined $volumedata->{$name}->{$attr});
            # FIXME: Don't update disk group from filesystem, only the reverse.
            #next if ($attr eq 'disk_group');
            my $p = $volume->__meta__->property($attr);
            next unless ($p);
            # Primary keys are immutable, don't try to update them
            $volume->$attr($volumedata->{$name}->{$attr})
                if (! $p->is_id and $p->is_mutable);
            $volume->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
        }
    }
    return 1;
}

=head2 purge_volumes
Iterate over all Volumes associated with this Filer, check is_current() and warn on all stale volumes.
=cut
sub validate_volumes {
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
=cut
sub purge_volumes {
    my $self = shift;
    $self->logger->error(__PACKAGE__ . " max age has not been specified\n")
        if (! defined $self->vol_maxage);
    $self->logger->error(__PACKAGE__ . " max age makes no sense: $self->vol_maxage\n")
        if ($self->vol_maxage < 0 or $self->vol_maxage !~ /\d+/);

    foreach my $volume (SDM::Disk::Volume->get( filername => $self->name )) {
        $volume->purge($self->vol_maxage);
    }
}

=head2 query_gpfs
The SSH bits of execute()
=cut
sub query_gpfs {
    my $self = shift;
    my $filer = shift;

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

    # Update Filer data that are not current
    eval {
        my @params = ( loglevel => $self->loglevel, hostname => $filer->name );
        push @params, ( allow_mount => $self->allow_mount ) if ($self->discover_groups);
        push @params, ( translate_path => $self->translate_path );
        push @params, ( discover_volumes => $self->discover_volumes );
        push @params, ( mount_point => $self->mount_point );

        my $gpfs = SDM::Utility::GPFS::DiskUsage->create( @params );
        unless ($gpfs) {
            $self->logger->error(__PACKAGE__ . " unable to query on filer " . $filer->name);
            return;
        }

        # Query disk usage numbers
        my $table = $gpfs->acquire_volume_data();
        # Volume data must be updated before GPFS data is updated below.
        $self->update_volumes( $table, $filer->name );

        $gpfs->delete();
        $filer->status(1);
        $filer->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
    };
    if ($@) {
        # log here, but not high priority, it's common
        $self->logger->warn(__PACKAGE__ . " error with query: $@");
        $filer->status(0);
    }

}

=head2 execute
Execute QueryGpfs() queries on a named Filer and stores disk usage information.
=cut
sub execute {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " execute");

    my @filers;
    if (defined $self->filername) {
        # FIXME: should this be a get(), do we want to allow transparently adding Filers?
        #@filers = SDM::Disk::Filer->get_or_create( name => $self->filername );
        @filers = SDM::Disk::Filer->get( name => $self->filername );
    } else {
        if ($self->force) {
            # If "force", get all Filers and query them even if status is 0.
            @filers = SDM::Disk::Filer->get();
        } else {
            # Query all filers that have status => 1...
            # This is what we use for a cron job.
            @filers = SDM::Disk::Filer->get( status => 1 );
        }
    }

    # Allow the ability to update a single physical_path on a filer.
    if (defined $self->physical_path) {
        unless ($self->filername) {
            $self->logger->error(__PACKAGE__ . " specify a filer to query for physical_path: " . $self->physical_path);
            return;
        }
    }

    unless (scalar @filers) {
        $self->logger->warn(__PACKAGE__ . " no filers to be scanned. Add filers if there are none, or use --force to scan all filers.");
    }

    foreach my $filer (@filers) {
        $self->query_gpfs($filer);
    }

    UR::Context->commit();

    # Now update disk group RRD files.
    my $rrd = SDM::Utility::DiskGroupRRD->create( loglevel => $self->loglevel );
    $rrd->run();

    return 1;
}

1;
