package System::Disk::Group;

use strict;
use warnings;

use System;
class System::Disk::Group {
    table_name => 'DISK_GROUP',
    id_by => [
        name => { is => 'Text' },
    ],
    has => [
        permissions     => { is => 'UnsignedInteger' },
        sticky          => { is => 'UnsignedInteger' },
        unix_gid        => { is => 'UnsignedInteger' },
        unix_uid        => { is => 'UnsignedInteger' },
    ],
    has_optional => [
        parent_group    => { is => 'Text' },
        subdirectory    => { is => 'Text', len => 255 },
        username        => { is => 'Text', len => 255 },
        created         => { is => 'DATE' },
        last_modified   => { is => 'DATE' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
    doc => 'Represents a disk group which contains any number of disk volumes',
};

1;
