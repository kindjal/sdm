
package SDM::SNMP::DiskUsage;

use strict;
use warnings;

use SDM;
use File::Basename qw/basename dirname/;
use Data::Dumper;
$Data::Dumper::Terse = 1;

class SDM::SNMP::DiskUsage {
    is => 'SDM::Utility::SNMP',
    has => [
        allow_mount => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Allow automounter to mount volumes to find disk groups'
        },
        discover_volumes => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Discover volumes on the target filer'
        }
    ],
    has_optional => [
        mount_point => {
            is => 'Text',
            default_value => '/gscmnt',
            doc => 'Mount point used by autofs to mount target filer.  Only for discover_volumes mode.'
        },
        translate_path => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Map physical_path /vol/homeXYZ to volume name XYZ, this is an old convention',
        }
    ],
    has_transient => [
        disk_groups => {
            default_value => {},
            is => 'HASH',
        }
    ]
};

=head2 _netapp_int32
Older netapps don't have a single 64 bit counter for disk space, but rather a "low" and "high"
counter that we put together for the final result.
=cut
sub _netapp_int32 {
    my $self = shift;
    my $low = shift;
    my $high = shift;
    if ($low >= 0) {
        return $high * 2**32 + $low;
    }
    if ($low < 0) {
        return ($high + 1) * 2**32 + $low;
    }
}

=head2 _get_disk_group_via_snmp
Again by convention, we split a volume space into directories to be assigned a "disk_group".
We can configure a Filer's snmpd to export a Table with disk group info.  This method gets that data.
=cut
sub _get_disk_group_via_snmp {
    my $self = shift;
    my $physical_path = shift;

    $self->logger->debug(__PACKAGE__ . " _get_disk_group_via_snmp($physical_path)");
    my $oid = '1.3.6.1.4.1.8072.1.3.2.4.1.2.15.100.105.115.107.95.103.114.111.117.112.95.110.97.109.101';

    unless ($self->disk_groups) {
        $self->disk_groups( $self->read_snmp_into_table($oid) );
    }
    foreach my $key (sort {$a <=> $b} keys %{$self->disk_groups}) {
        my $value = pop @{ [ values %{ $self->disk_groups->{$key} } ] };
        my $path = dirname $value;
        my $group = basename $value;
        $group =~ s/^DISK_//;
        if ($path eq $physical_path) {
            $self->logger->debug(__PACKAGE__ . " _get_disk_group_via_snmp returns $group for $physical_path");
            return $group;
        }
    }
    $self->logger->debug(__PACKAGE__ . " _get_disk_group_via_snmp returns undef for $physical_path");
    return undef;
}

=head2 _get_disk_group
Again by convention, we split a volume space into directories to be assigned a "disk_group".
Try to determine the disk group:
 - By looking at the Volume data we store.
 - By looking at the SNMP data we query.
 - By looking for a touch file in the volume mount path (optionally).
=cut
sub _get_disk_group {
    my $self = shift;
    my $physical_path = shift;
    my $mount_path = shift;
    $self->logger->debug(__PACKAGE__ . " _get_disk_group($physical_path)");
    return unless ($physical_path);

    my $disk_group;

    # Do we already have the disk group name?
    my @volumes = SDM::Disk::Volume->get( physical_path => $physical_path );
    my $volume = shift @volumes;
    if ($volume) {
        my $disk_group = $volume->disk_group;
        if (defined $disk_group) {
            $self->logger->debug(__PACKAGE__ . " _get_disk_group returns existing group $disk_group");
            return $disk_group;
        }
    }

    # FIXME: Site specific
    # Special case of '.snapshot' mounts
    my $base = basename $physical_path;
    if ($base eq ".snapshot") {
        $self->logger->debug(__PACKAGE__ . " _get_disk_group special group SYSTEMS_SNAPSHOT");
        return 'SYSTEMS_SNAPSHOT';
    }

    # Determine the disk group name
    if ($self->hosttype eq 'linux') {
        my $disk_group = $self->_get_disk_group_via_snmp($physical_path);
        # If not defined or empty, go to mount point and look for touch file.
        if (defined $disk_group and $disk_group ne '') {
            $self->logger->debug(__PACKAGE__ . " _get_disk_group snmp returns: $disk_group");
            return $disk_group;
        }
    }

    unless ($self->allow_mount) {
        $self->logger->debug(__PACKAGE__ . " _get_disk_group returns undef");
        return;
    }

    # FIXME: Site specific
    # This will actually mount a mount point via automounter.
    # Be careful to not overwhelm NFS servers.
    # NB. This is a convention from Storage team to use DISK_ touchfiles.
    if ($mount_path) {
        my $file = pop @{ [ glob("$mount_path/DISK_*") ] };
        if (defined $file and $file =~ m/^\S+\/DISK_(\S+)/) {
            $disk_group = $1;
        } else {
            $disk_group = undef;
        }
    }

    $self->logger->debug(__PACKAGE__ . " _get_disk_group filesystem mount returns: " . Data::Dumper::Dumper $disk_group);
    return $disk_group;
}

=head2 _convert_to_volume_data
Convert the SNMP query results to attributes of our Volumes.
This is the final result that our caller is asking for.
=cut
sub _convert_to_volume_data {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " convert_to_volume_data");
    my $snmp_table = shift;
    my $volume_table = {};
    foreach my $dfIndex (keys %$snmp_table) {

        # Convert result blocks to bytes
        my $total;
        my $used;
        my $physical_path;
        if ($self->hosttype eq 'netapp') {
            # Skip devices that are not fixed disks.
            next unless ($snmp_table->{$dfIndex}->{'dfType'} eq 'flexibleVolume(2)');
            if (exists $snmp_table->{$dfIndex}->{'df64TotalKBytes'}) {
                $total = $snmp_table->{$dfIndex}->{'df64TotalKBytes'};
                $used  = $snmp_table->{$dfIndex}->{'df64UsedKBytes'};
            } else {
                # Fix 32 bit integer stuff
                my $low = $snmp_table->{$dfIndex}->{'dfLowTotalKBytes'};
                my $high = $snmp_table->{$dfIndex}->{'dfHighTotalKBytes'};
                $total = $self->_netapp_int32($low,$high);

                $low = $snmp_table->{$dfIndex}->{'dfLowUsedKBytes'};
                $high = $snmp_table->{$dfIndex}->{'dfHighUsedKBytes'};
                $used = $self->_netapp_int32($low,$high);
            }
            $physical_path = $snmp_table->{$dfIndex}->{'dfFileSys'};
        } else {
            # Skip devices that are not fixed disks.
            next unless ($snmp_table->{$dfIndex}->{'hrStorageType'} eq 'HOST-RESOURCES-TYPES::hrStorageFixedDisk');
            $physical_path = $snmp_table->{$dfIndex}->{'hrStorageDescr'};
            # Correct for block size
            my $correction = [ split(/\s+/,$snmp_table->{$dfIndex}->{'hrStorageAllocationUnits'}) ]->[0];
            $correction = $correction / 1024;
            $total = $snmp_table->{$dfIndex}->{'hrStorageSize'} * $correction;
            $used  = $snmp_table->{$dfIndex}->{'hrStorageUsed'} * $correction;
        }

        next if ($physical_path eq "/");

        # FIXME: we're either discovering volumes or updating volumes.
        # If discover, check if translate path is set, mount_point must be set,
        unless ($self->mount_point) {
            $self->logger->error(__PACKAGE__ . " no mount_point defined, use --mount-point");
            return;
        }

        if ($self->translate_path) {
            # FIXME: Local to TGI only
            $physical_path =~ s/\/home/\//; # strip out ^home to satisfy an old TGI convention
        }

        my $mount_path;
        my ($toss,$dev,$volume_name) = split(/\//,$physical_path,3);
        $mount_path = $self->mount_point . "/" . $volume_name;
        $mount_path = undef if ($physical_path =~ /.snapshot/);

        $volume_table->{$physical_path} = {} unless (exists $volume_table->{$physical_path});
        $volume_table->{$physical_path}->{mount_path} = $mount_path;
        $volume_table->{$physical_path}->{used_kb} = $used;
        $volume_table->{$physical_path}->{total_kb} = $total;
        $volume_table->{$physical_path}->{physical_path} = $physical_path;
        $volume_table->{$physical_path}->{disk_group} = $self->_get_disk_group($physical_path,$mount_path);
    }
    $self->logger->debug(__PACKAGE__ . " " . scalar(keys %$volume_table) . " items");
    return $volume_table;
}

=head2 acquire
Run this subclass of SNMP to gather DiskUsage data.
=cut
sub acquire_volume_data {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " acquire_volume_data");
    unless ($self->hosttype) {
        $self->logger->error(__PACKAGE__ . " can't determine hosttype of host: " . $self->hostname);
        return;
    }
    my $oid = $self->hosttype eq 'netapp' ?  'dfTable' : 'hrStorageTable';
    my $snmp_table = $self->read_snmp_into_table($oid);
    return unless ($snmp_table);
    my $volume_table = $self->_convert_to_volume_data( $snmp_table );
    return $volume_table;
}

package SDM::Disk::Filer::Command::QuerySnmp;

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

class SDM::Disk::Filer::Command::QuerySnmp {
    is => 'SDM::Command::Base',
    has_optional => [
        filername => {
            # If I use is => Filer here, UR errors out immediately if the filer doesn't exist.
            # If I use is => Text, then I can use get_or_create to add on the fly, or query them all.
            #is => 'SDM::Disk::Filer',
            is => 'Text',
            doc => 'SNMP query the named filer, which we assume resolves via DNS to the IP of a host',
        },
        type => {
            is => 'Text',
            doc => 'Specify filer type if you are adding a new filer with --filername',
            valid_values => ['gpfs','polyserve','vcf','netapp','nfs']
        },
        force => {
            is => 'Boolean',
            default => 0,
            doc => 'Query all filers regardless of status',
        },
        allow_mount => {
            is => 'Boolean',
            default => 0,
            doc => 'Allow mounting of filesystems to discover disk groups rather than only relying on SNMP',
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
            doc => 'Create volumes based on what SNMP discovers, otherwise only update volumes already defined',
        },
        is_current => {
            is => 'Boolean',
            default => 0,
            doc => 'Check currency status',
        },
        physical_path => {
            is => 'Text',
            doc => 'SNMP query the named filer for this export',
        },
        query_paths => {
            is => 'Boolean',
            doc => 'SNMP query the named filer for exports, but not usage',
        },
    ],
    doc => 'Queries volume usage via SNMP',
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
Updates volume usage information. Blah blah blah details blah.
EOS
}

=head2 _update_volumes
Update SNMP data for all Volumes associated with this Filer.
=cut
sub _update_volumes {
    my $self = shift;
    my $volumedata = shift;
    my $filer = shift;
    my $filername = $filer->name;

    unless ($filer->name) {
        $self->logger->error(__PACKAGE__ . " _update_volumes(): no filer given");
        return;
    }
    unless ($volumedata) {
        $self->logger->warn(__PACKAGE__ . " _update_volumes(): filer $filername returned empty SNMP volumedata");
        return;
    }

    $self->logger->warn(__PACKAGE__ . " _update_volumes($filername)");

    unless ($self->physical_path) {
        # QuerySnmp First find and remove volumes in the DB that are not detected on this filer
        # For this filer, find any stored volumes that aren't present in the volumedata retrieved via SNMP.
        # Note that we skip this step if we specified a single physical_path to update.
        foreach my $volume ( SDM::Disk::Volume->get( filername => $filername ) ) {
            foreach my $path ($volume->physical_path) {
                if ( ! defined $volumedata->{$path} ) {
                    $self->logger->warn(__PACKAGE__ . " volume is no longer exported by filer '$filername': $path");
                    $volume->delete;
                }
            }
        }
        return 1 if ($self->cleanonly);
    }

    foreach my $physical_path (keys %$volumedata) {

        next if ($physical_path eq '/');

        # Ensure we have the Group before we update this attribute of a Volume
        my $group_name = $volumedata->{$physical_path}->{disk_group};
        if ($group_name) {
            my $group;
            if ($self->discover_groups) {
                $group = SDM::Disk::Group->get_or_create( name => $group_name );
                $self->logger->debug(__PACKAGE__ . " created disk group: $group_name");
            } else {
                $group = SDM::Disk::Group->get( name => $group_name );
            }
            unless ($group) {
                $self->logger->error(__PACKAGE__ . " ignoring currently unknown disk group: $group_name");
                next;
            }
        }

        #my $volume = SDM::Disk::Volume->get_or_create( filername => $filername, physical_path => $physical_path );
        my $volume = SDM::Disk::Volume->get( filername => $filername, physical_path => $physical_path );
        unless ($volume) {
            unless ($self->discover_volumes) {
                $self->logger->warn(__PACKAGE__ . " ignoring new volume: $filername, $physical_path, consider --discover-volumes");
                next;
            }
            $volume = SDM::Disk::Volume->create( filername => $filername, physical_path => $physical_path );
            $self->logger->error(__PACKAGE__ . " create volume: $filername, $physical_path");
            unless ($volume) {
                $self->logger->error(__PACKAGE__ . " failed to get_or_create volume: $filername, $physical_path");
                next;
            }
        }
        $self->logger->debug(__PACKAGE__ . " found volume: $filername, $physical_path");
        foreach my $attr (keys %{ $volumedata->{$physical_path} }) {
            next unless (defined $volumedata->{$physical_path}->{$attr});
            # FIXME: Don't update disk group from filesystem, only the reverse.
            #next if ($attr eq 'disk_group');
            my $p = $volume->__meta__->property($attr);
            # Primary keys are immutable, don't try to update them
            $volume->$attr($volumedata->{$physical_path}->{$attr})
                if ($p and ! $p->is_id and $p->is_mutable);
            $volume->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
        }
        # Special bits for duplicate filers
        my @duplicate_filers = SDM::Disk::Filer->get( duplicates => $filername );
        foreach my $dup_filer (@duplicate_filers) {
            $volume->assign($dup_filer);
        }
    }
    return 1;
}

=head2 _validate_volumes
Iterate over all Volumes associated with this Filer, check is_current() and warn on all stale volumes.
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

=head2 _purge_volumes
Iterate over all Volumes associated with this Filer, check is_current() and purge all stale volumes.
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

=head2 _query_snmp
The SNMP bits of execute()
=cut
sub _query_snmp {
    my $self = shift;
    my $filer = shift;

    # Just check if Filer is_current
    $self->logger->warn(__PACKAGE__ . " running SNMP query on filer " . $filer->name);
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
        my $snmp = SDM::SNMP::DiskUsage->create( @params );
        unless ($snmp) {
            $self->logger->error(__PACKAGE__ . " unable to query SNMP on filer " . $filer->name);
            return;
        }

        # Query SNMP for disk usage numbers
        # This is different from read_snmp_into_table() because we have platform depenedent volume data
        # that we need to parse and apply logic to.  See SNMP::DiskUsage for details.
        my $table = $snmp->acquire_volume_data();
        # Volume data must be updated before GPFS data is updated below.
        $self->_update_volumes( $table, $filer );

        $snmp->delete();
        $filer->status(1);
        $filer->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
    };
    if ($@) {
        # log here, but not high priority, it's common
        $self->logger->warn(__PACKAGE__ . " error with SNMP query: $@");
        $filer->status(0);
    }

}

=head2 execute
Execute QuerySnmp() queries SNMP on a named Filer and stores disk usage information.
=cut
sub execute {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " execute");

    my @filers;
    if (defined $self->filername) {
        @filers = SDM::Disk::Filer->get( name => $self->filername );
        unless (@filers) {
            @filers = SDM::Disk::Filer->create( name => $self->filername );
            unless (@filers) {
                $self->logger->error(__PACKAGE__ . " unable to create filer: " . $self->filername);
                return;
            }
            $self->logger->info(__PACKAGE__ . " added new filer " . $self->filername);
        }
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
        $self->_query_snmp($filer);
    }

    UR::Context->commit();

    # Now update disk group RRD files.
    my $rrd = SDM::Utility::DiskGroupRRD->create( loglevel => $self->loglevel );
    $rrd->run();

    return 1;
}

1;
