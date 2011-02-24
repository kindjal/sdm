package System::DiskFiler;

use strict;
use warnings;

use System;
class System::DiskFiler {
    type_name => 'disk filer',
    table_name => 'DISK_FILER',
    id_by => [
        filer_id => { is => 'INTEGER' },
    ],
    has => [
        comments      => { is => 'VARCHAR(255)', is_optional => 1 },
        created       => { is => 'DATE', is_optional => 1 },
        filesystem    => { is => 'VARCHAR(255)', is_optional => 1 },
        hostname      => { is => 'VARCHAR(255)' },
        last_modified => { is => 'DATE', is_optional => 1 },
        status        => { is => 'UNSIGNED INTEGER' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

1;
