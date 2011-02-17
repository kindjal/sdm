package System::Disk::Volume::Command::Create;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command::Create {
    is => 'System::Command::Base',
    has => [
        subject_class_name  => {
            is_constant => 1,
            value => 'System::Disk::Volume',
        },
        show => { 
            default_value => 'mount_path,physical_path,df_id'
        },
    ],
};

1;
