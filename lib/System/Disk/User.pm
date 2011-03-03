package System::Disk::User;

use strict;
use warnings;

use System;
class System::Disk::User {
    table_name => 'DISK_USER',
    id_by => [
        email => { is => 'Text', len => 255 },
    ],
    has_optional => [
        created       => { is => 'DATE' },
        last_modified => { is => 'DATE' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

1;
