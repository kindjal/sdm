package System::Disk::Filerpath;

use strict;
use warnings;

use System;

class System::Disk::Filerpath {
    table_name => 'DISK_FILER_PATH',
    id_by => [
        filername  => { is => 'Text', len => 255 },
        mount_path => { is => 'Text', len => 255 },
    ],
    has => [
        filer     => { is => 'System::Disk::Filer', id_by => 'filername', len => 255, constraint_name => 'DISK_FILER_PATH_FK' },
        volume    => { is => 'System::Disk::Volume', id_by => 'mount_path' },
    ],
    has_optional => [
        created         => { is => 'DATE' },
        last_modified   => { is => 'DATE' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

1;
