package System::Disk::Volume;

use strict;
use warnings;

use System;
class System::Disk::Volume {
    table_name => 'DISK_VOLUME',
    id_by => [
        dv_id         => { is => 'INTEGER' },
    ],
    has => [
        mount_path    => { is => 'VARCHAR(255)' },
        physical_path => { is => 'VARCHAR(255)' },
        total_kb      => { is => 'UNSIGNED INTEGER' },
        used_kb       => { is => 'UNSIGNED INTEGER' },
        df_id         => { is => 'INTEGER' },
    ],
    #has_many_optional => [
    #    disk_group_names => { via => 'groups', to => 'disk_group_name' },
    #    groups           => { is => 'System::Disk::Group', via => 'assignments', to => 'group' },
    #    assignments      => { is => 'System::Disk::Assignment', id_by => 'dv_id', reverse_as => 'volume' },
    #],
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
