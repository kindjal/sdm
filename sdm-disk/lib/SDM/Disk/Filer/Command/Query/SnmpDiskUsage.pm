
package SDM::Disk::Filer::Command::Query::SnmpDiskUsage;

use strict;
use warnings;

use SDM;
use File::Basename qw/basename dirname/;
use Data::Dumper;
$Data::Dumper::Terse = 1;

class SDM::Disk::Filer::Command::Query::SnmpDiskUsage {
    is => 'SDM::Utility::SNMP',
    has => [
        filer => {
            is => 'SDM::Disk::Filer',
            doc => 'The Filer to query'
        },
        hostname => {
            is => 'Text',
            via => 'filer',
            to => 'master',
            doc => 'Hostname of the cluster master'
        },
        allow_mount => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Allow automounter to mount volumes to find disk groups'
        },
        discover_volumes => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Discover volumes on the target filer'
        },
        discover_groups => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Discover groups on the target filer'
        }
    ],
    has_optional => [
        mount_path_rule => {
            is => 'Text',
            default_value => '^(/vol/aggr0|/vol):/gscmnt',
            doc => 'Colon separated rule to translate physical_path to mount_path.  Used with discover_volumes. eg: /vol:/gscmnt'
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

        if ($self->translate_path) {
            # FIXME: Local to TGI only
            $physical_path =~ s/\/home/\//; # strip out ^home to satisfy an old TGI convention
        }

        my $mount_path = $physical_path;
        my ($from,$to) = split(/:/,$self->mount_path_rule);
        $mount_path =~ s/$from/$to/;
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

=head2 _update_volumes
Update SNMP data for all Volumes associated with this Filer.
=cut
sub _update_volumes {
    my $self = shift;
    my $volumedata = shift;

    my $filer = $self->filer;
    my $filername = $filer->name;

    unless ($filer) {
        $self->logger->error(__PACKAGE__ . " _update_volumes(): no filer given");
        return;
    }
    unless ($volumedata) {
        $self->logger->warn(__PACKAGE__ . " _update_volumes(): filer $filername returned empty volumedata");
        return;
    }

    $self->logger->warn(__PACKAGE__ . " _update_volumes($filername)");

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
    $filer->status(1);
    $filer->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
    return 1;
}

=head2 acquire
Run this subclass of SNMP to gather DiskUsage data.
=cut
sub acquire_volume_data {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " acquire_volume_data");

    unless ($self->hostname) {
        $self->logger->error(__PACKAGE__ . " filer '" . $self->filer->name . "' has no master host associated with it.");
        return;
    }

    unless ($self->hosttype) {
        $self->logger->error(__PACKAGE__ . " can't determine hosttype of host: " . $self->hostname);
        return;
    }

    my $oid = $self->hosttype eq 'netapp' ?  'dfTable' : 'hrStorageTable';
    my $snmp_table = $self->read_snmp_into_table($oid);
    return unless ($snmp_table);
    my $volume_table = $self->_convert_to_volume_data( $snmp_table );
    $self->_update_volumes( $volume_table );
}

1;
