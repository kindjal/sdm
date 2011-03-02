package System::Disk::Assignment::Command::List;

use strict;
use warnings;

use System;

class System::Disk::Assignment::Command::List {
    is => 'UR::Object::Command::List',
    has => [
        subject_class_name  => {
            is_constant => 1,
            value => 'System::Disk::Assignment',
        },
        show => {
            default_value => 'name,filername,subdirectory,mount_path,absolute_path,percent_full'
        },
    ],
};

sub sub_command_sort_position { 4 }

1;
