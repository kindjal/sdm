package System::DiskGroup;

use strict;
use warnings;

use System;
class System::DiskGroup {
    type_name => 'disk group',
    table_name => 'DISK_GROUP',
    id_by => [
        group_id => { is => 'INTEGER' },
    ],
    has => [
        created         => { is => 'DATE', is_optional => 1 },
        last_modified   => { is => 'DATE', is_optional => 1 },
        name            => { is => 'VARCHAR(255)' },
        parent_group_id => { is => 'INTEGER', is_optional => 1 },
        permissions     => { is => 'UNSIGNED INTEGER' },
        sticky          => { is => 'UNSIGNED INTEGER' },
        subdirectory    => { is => 'VARCHAR(255)', is_optional => 1 },
        unix_gid        => { is => 'UNSIGNED INTEGER' },
        unix_uid        => { is => 'UNSIGNED INTEGER' },
        username        => { is => 'VARCHAR(255)', is_optional => 1 },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
    doc => 'Represents a disk group which contains any number of disk volumes',
};

1;
