package System::DiskArray;

use strict;
use warnings;

use System;
class System::DiskArray {
    type_name => 'disk array',
    table_name => 'DISK_ARRAY',
    id_by => [
        array_id => { is => 'INTEGER' },
    ],
    has => [
        created       => { is => 'DATE', is_optional => 1 },
        last_modified => { is => 'DATE', is_optional => 1 },
        model         => { is => 'VARCHAR(255)' },
        size          => { is => 'UNSIGNED INTEGER' },
        type          => { is => 'VARCHAR(255)' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

1;
