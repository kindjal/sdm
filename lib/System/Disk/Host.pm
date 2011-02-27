package System::Disk::Host;

use strict;
use warnings;

use System;
class System::Disk::Host {
    table_name => 'DISK_HOST',
    id_by => [
        host_id       => { is => 'INTEGER' },
    ],
    has => [
        hostname      => { is => 'VARCHAR(255)' },
        filer         => { is => 'System::Disk::Filer', id_by => 'filer_id' },
    ],
    has_many => [
        arrays        => { is => 'System::Disk::Array', reverse_as => 'host' },
    ],
    has_optional => [
        comments      => { is => 'VARCHAR(255)' },
        created       => { is => 'DATE' },
        last_modified => { is => 'DATE' },
        location      => { is => 'VARCHAR(255)' },
        os            => { is => 'VARCHAR(255)' },
        status        => { is => 'UNSIGNED INTEGER' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

1;
