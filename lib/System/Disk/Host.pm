package System::Disk::Host;

use strict;
use warnings;

use System;
class System::Disk::Host {
    table_name => 'DISK_HOST',
    id_by => [
        host_id => { is => 'INTEGER' },
    ],
    has => [
        comments      => { is => 'VARCHAR(255)', is_optional => 1 },
        created       => { is => 'DATE', is_optional => 1 },
        hostname      => { is => 'VARCHAR(255)' },
        last_modified => { is => 'DATE', is_optional => 1 },
        location      => { is => 'VARCHAR(255)', is_optional => 1 },
        os            => { is => 'VARCHAR(255)', is_optional => 1 },
        status        => { is => 'UNSIGNED INTEGER', is_optional => 1 },
        filer         => { is => 'System::Disk::Filer', id_by => 'filer_id', constraint_name => 'HOST_FILER_FK' },
        filer_id      => { is => 'INTEGER', implied_by => 'filer' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

1;
