package System::Disk::User;

use strict;
use warnings;

use System;
class System::Disk::User {
    table_name => 'DISK_USER',
    id_by => [
        user_id => { is => 'Integer' },
    ],
    has => [
        created       => { is => 'DATE', is_optional => 1 },
        email         => { is => 'Text', len => 255 },
        last_modified => { is => 'DATE', is_optional => 1 },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

1;
