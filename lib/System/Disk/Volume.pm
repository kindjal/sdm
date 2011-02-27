package System::Disk::Volume;

use strict;
use warnings;

use System;
class System::Disk::Volume {
    table_name => 'DISK_VOLUME',
    id_by => [
        volume_id => { is => 'INTEGER', implied_by => 'disk_group' },
    ],
    has => [
        filer_id           => { is => 'INTEGER' },
        mount_path         => { is => 'VARCHAR(255)' },
        physical_path      => { is => 'VARCHAR(255)' },
        total_kb           => { is => 'UNSIGNED INTEGER' },
        used_kb            => { is => 'UNSIGNED INTEGER' },
    ],
    has_optional => [
        created       => { is => 'DATE' },
        last_modified => { is => 'DATE' },
        disk_group    => { is => 'System::Disk::Group', id_by => 'volume_id' },
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
