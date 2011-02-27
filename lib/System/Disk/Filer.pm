package System::Disk::Filer;

use strict;
use warnings;

use System;
class System::Disk::Filer {
    table_name => 'DISK_FILER',
    id_by => [
        filer_id        => { is => 'INTEGER' },
    ],
    has => [
        name            => { is => 'Text', len => 255 },
    ],
    has_optional => [
        comments        => { is => 'Text', len => 255 },
        created         => { is => 'DATE' },
        filesystem      => { is => 'Text', len => 255 },
        last_modified   => { is => 'DATE' },
        status          => { is => 'UNSIGNED INTEGER' },
    ],
    has_many => [
        hosts           => { is => 'System::Disk::Host', reverse_as => 'filer' },
        arrays          => { is => 'System::Disk::Array', via => 'hosts', to => 'arrays' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

1;
