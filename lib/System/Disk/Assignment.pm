package System::Disk::Assignment;

use strict;
use warnings;

use System;
class System::Disk::Assignment {
    table_name => 'DISK_VOLUME_GROUP',
    id_by => [
        group_id  => { is => 'Integer', implied_by => 'group' },
        volume_id => { is => 'Integer', implied_by => 'volume' },
    ],
    has => [
        disk_group_name      => { via => 'group' },
        user_name            => { via => 'group' },
        group_name           => { via => 'group' },
        subdirectory         => { via => 'group' },
        mount_path           => { via => 'volume' },
        total_kb             => { via => 'volume' },
        unallocated_kb       => { via => 'volume' },
        percent_full         => { calculate_from => 'absolute_path',
                                  calculate => q(
                my @pct_full = `df -h $absolute_path`;
                my @split_pct_full = split(/%/,$pct_full[-1]);
                @split_pct_full = split (/ /,$split_pct_full[0]);
                return $split_pct_full[-1]; ) },
        absolute_path       => { calculate_from => [ 'mount_path', 'subdirectory' ],
                                  calculate => q( return $mount_path .'/'. $subdirectory; ) },
        group               => { is => 'System::Disk::Group', id_by => 'group_id', constraint_name => 'DISK_VOLUME_GROUP_GROUP_ID_DISK_GROUP_GROUP_ID_FK' },
        volume              => { is => 'System::Disk::Volume', id_by => 'volume_id', constraint_name => 'VOLUME_GROUP_VOLUME_FK' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

1;
