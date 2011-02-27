package System::Disk::Array;

use strict;
use warnings;

use System;
class System::Disk::Array {
    type_name               => 'disk array',
    table_name              => 'DISK_ARRAY',
    id_by => [
        array_id            => { is => 'INTEGER' },
    ],
    has => [
        host_id             => { is => 'INTEGER', implied_by => 'host' },
        host                => { is => 'System::Disk::Host', id_by => 'host_id', constraint_name => 'ARRAY_HOST_FK' },
        model               => { is => 'VARCHAR(255)' },
        size                => { is => 'UNSIGNED INTEGER' },
        type                => { is => 'VARCHAR(255)' },
        #System::Disk::Host => { is => 'System::Disk::Host', id_by => 'host_id', constraint_name => 'ARRAY_HOST_FK' },
    ],
    has_optional => [
        created             => { is => 'DATE' },
        last_modified       => { is => 'DATE' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

1;
