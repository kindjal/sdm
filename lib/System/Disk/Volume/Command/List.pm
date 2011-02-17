package System::Disk::Volume::Command::List;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command::List {
    is => 'UR::Object::Command::List',
    has => [
        subject_class_name  => {
            is_constant => 1,
            value => 'System::Disk::Volume',
        },
        show => { 
            #default_value => 'mount_path,total_kb,disk_group_names' 
            default_value => 'physical_path,mount_path,total_kb' 
        },
    ],
};

#sub sub_command_sort_position { 4 }

1;
