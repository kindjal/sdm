package System::Disk::Group;

use strict;
use warnings;

use System;
class System::Disk::Group {
    table_name => 'DISK_GROUP',
    id_by => [
        group_id => { is => 'Integer' },
    ],
    has => [
        created         => { is => 'DATE', is_optional => 1 },
        last_modified   => { is => 'DATE', is_optional => 1 },
        name            => { is => 'Text', len => 255 },
        parent_group_id => { is => 'Integer', is_optional => 1 },
        permissions     => { is => 'UnsignedInteger' },
        sticky          => { is => 'UnsignedInteger' },
        subdirectory    => { is => 'Text', len => 255, is_optional => 1 },
        unix_gid        => { is => 'UnsignedInteger' },
        unix_uid        => { is => 'UnsignedInteger' },
        username        => { is => 'Text', len => 255, is_optional => 1 },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
    doc => 'Represents a disk group which contains any number of disk volumes',
};

1;
