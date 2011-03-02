package System::Disk::Volume;

use strict;
use warnings;

use System;
class System::Disk::Volume {
    table_name => 'DISK_VOLUME',
    id_by => [
        volume_id => { is => 'Integer' },
    ],
    has => [
        filer         => { is => 'System::Disk::Filer', id_by => 'filername', constraint_name => 'VOLUME_FILER_FK' },
        mount_path    => { is => 'Text', len => 255 },
        physical_path => { is => 'Text', len => 255 },
        total_kb      => { is => 'UnsignedInteger' },
        used_kb       => { is => 'UnsignedInteger' },
    ],
    has_optional => [
        # FIXME: should be id_by name
        disk_group    => { is => 'System::Disk::Group', id_by => 'volume_id', constraint_name => 'VOLUME_GROUP_FK' },
        created       => { is => 'DATE' },
        last_modified => { is => 'DATE' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

__END__

sub unusable_volume_percent { return .05 }
sub maximum_reserve_size { return 1_073_741_824 } # 1 TB

sub most_recent_allocation {
    my $self = shift;
    # Unless otherwise specified, the objects returned by this get will be sorted by increasing
    # id value. This is ONLY true if the id is numeric and single-column. If any fields other than
    # allocator id are ever added to the id_by property of allocations, this get will need to be modified
    my @allocations = System::Disk::Allocation->get(mount_path => $self->mount_path);
    return unless @allocations;
    return $allocations[-1];
}

1;
