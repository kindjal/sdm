
package SDM::Utility::SNMP::DiskUsage;

use strict;
use warnings;

use SDM;
use File::Basename qw/basename dirname/;

class SDM::Utility::SNMP::DiskUsage {
    is => 'SDM::Utility::SNMP',
    has => [
        allow_mount => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Allow automounter to mount volumes to find disk groups',
        },
        gpfs => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Target SNMP host supports GPFS subagent',
        }
    ],
    has_constant => [
        ignorable_linux_types => {
            is => 'List',
            value => [
                "HOST-RESOURCES-TYPES::hrStorageOther",
                "HOST-RESOURCES-TYPES::hrStorageRam",
                "HOST-RESOURCES-TYPES::hrStorageVirtualMemory",
            ]
        },
        ignorable_netapp_types => {
            is => 'List',
            value => [
                "aggregate(3)",
                "flexibleVolume(2)"
            ]
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

=head2 _translate_mount_point
A "Volume" as reported by SNMP, eg. hrStorageDescr, is made available via some mount point.
These are named by convention (and thus Site specific).  Parse the volume/physical_path to
the conventional mount_path.
=cut
sub _translate_mount_point {
    # Map a volume to a mount point.
    my $self = shift;
    my $volume = shift;
    $self->logger->debug(__PACKAGE__ . " _translate_mount_point($volume)");

    # FIXME: This is site specific
    # These mount points are agreed upon by convention.
    # Return empty if the $volume is shorter than the
    # hash keys, preventing a substr() error on too short mounts.
    return '' if (length($volume) <= 4);
    my $mapping = {
        qr|^/vol|       => "/gscmnt" . substr($volume,4),
        qr|^/home(\d+)| => "/gscmnt" . substr($volume,5),
        qr|^/gpfs(\S+)| => $volume,
    };

    foreach my $rx (keys %$mapping) {
        return $mapping->{$rx} if ($volume =~ /$rx/);
    }
    $self->logger->error("can't produce mount_path for volume: $volume\n");
    return;
}

=head2 _get_disk_group_via_snmp
Again by convention, we split a volume space into directories to be assigned a "disk_group".
We can configure a Filer's snmpd to export a Table with disk group info.  This method gets that data.
=cut
sub _get_disk_group_via_snmp {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " _get_disk_group_via_snmp");
    my $physical_path = shift;

    #my $oid = 'nsExtendOutLine-group' => '1.3.6.1.4.1.8072.1.3.2.4.1.2.15.100.105.115.107.95.103.114.111.117.112.95.110.97.109.101',
    my $oid = '1.3.6.1.4.1.8072.1.3.2.4.1.2.15.100.105.115.107.95.103.114.111.117.112.95.110.97.109.101';
    $self->command( 'snmpwalk' );
    my $results = $self->run( $oid );
    foreach my $hash (@$results) {
        my $path = dirname $hash->{value};
        my $group = basename $hash->{value};
        return $group if ($path eq $physical_path);
    }
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
    $self->logger->debug(__PACKAGE__ . " _get_disk_group");
    my $physical_path = shift;
    my $mount_path = shift;

    my $disk_group;

    # Do we already have the disk group name?
    if (defined $mount_path) {
        my @volumes = SDM::Disk::Volume->get( mount_path => $mount_path );
        my $volume = shift @volumes;
        if ($volume) {
            $disk_group = $volume->disk_group;
            return $disk_group if (defined $disk_group);
        }
    }

    # FIXME: Site specific
    # Special case of '.snapshot' mounts
    my $base = basename $physical_path;
    if ($base eq ".snapshot") {
        return 'SYSTEMS_SNAPSHOT';
    }

    # Determine the disk group name
    if ($self->hosttype eq 'linux') {
        my $disk_group = $self->_get_disk_group_via_snmp($physical_path);
        # If not defined or empty, go to mount point and look for touch file.
        return $disk_group if (defined $disk_group and $disk_group ne '');
    }

    return unless ($self->allow_mount);

    # FIXME: Site specific
    # This will actually mount a mount point via automounter.
    # Be careful to not overwhelm NFS servers.
    # NB. This is a convention from Storage team to use DISK_ touchfiles.
    my $file = pop @{ [ glob("$mount_path/DISK_*") ] };
    if (defined $file and $file =~ m/^\S+\/DISK_(\S+)/) {
        $disk_group = $1;
    } else {
        $disk_group = undef;
    }

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
        my $volume;
        if ($self->hosttype eq 'netapp') {
            # Skip volumes that are not fixed disks.
            #next if (grep /$snmp_table->{$dfIndex}->{'hrStorageType'}/, @{ $self->ignorable_netapp_types } );
            next unless ($snmp_table->{$dfIndex}->{'hrStorageType'} eq 'flexibleVolume(2)');
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
            $volume = $snmp_table->{$dfIndex}->{'dfFileSys'};
        } else {
            # Skip volumes that are not fixed disks.
            #next if (grep /$snmp_table->{$dfIndex}->{'hrStorageType'}/, @{ $self->ignorable_linux_types } );
            next unless ($snmp_table->{$dfIndex}->{'hrStorageType'} eq 'HOST-RESOURCES-TYPES::hrStorageFixedDisk');
            $volume = $snmp_table->{$dfIndex}->{'hrStorageDescr'};
            # Correct for block size
            my $correction = [ split(/\s+/,$snmp_table->{$dfIndex}->{'hrStorageAllocationUnits'}) ]->[0];
            $correction = $correction / 1024;
            $total = $snmp_table->{$dfIndex}->{'hrStorageSize'} * $correction;
            $used  = $snmp_table->{$dfIndex}->{'hrStorageUsed'} * $correction;
        }

        my $mount_path = $self->_translate_mount_point($volume);

        $volume_table->{$volume} = {} unless (exists $volume_table->{$volume});
        $volume_table->{$volume}->{mount_path} = $mount_path;
        $volume_table->{$volume}->{used_kb} = $used;
        $volume_table->{$volume}->{total_kb} = $total;
        $volume_table->{$volume}->{physical_path} = $volume;
        $volume_table->{$volume}->{disk_group} = $self->_get_disk_group($volume,$mount_path);
    }
    $self->logger->debug(__PACKAGE__ . " " . scalar(keys %$volume_table) . " items");
    return $volume_table;
}

=head2 acquire
Run this subclass of SNMP to gather DiskUsage data.
=cut
sub acquire_volume_data {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " acquire");
    my $oid = $self->hosttype eq 'netapp' ?  'dfTable' : 'hrStorageTable';
    my $snmp_table = $self->read_snmp_into_table($oid);
    my $volume_table = $self->_convert_to_volume_data( $snmp_table );
    return $volume_table;
}

=head2 detect_gpfs
Determine of the target Filer is GPFS by looking for gpfs package OID.
=cut
sub detect_gpfs {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " detect_gpfs(" . $self->hostname . ")");

    $self->command('snmpwalk');
    my $results = $self->run( 'hrSWInstalledName' );
    unless ($results) {
        $self->logger->error(__PACKAGE__ . " target host " . $self->hostname . " returns nothing for hrSWInstalledName");
        $self->gpfs(0);
        return $self->gpfs;
    }

    foreach my $item (@$results) {
        if ($item->{value} =~ /^"gpfs.base/) {
            $self->logger->debug(__PACKAGE__ . " " . $self->hostname . " is gpfs");
            $self->gpfs(1);
        }
    }
    return $self->gpfs;
}

1;
