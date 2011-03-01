package System::Disk::Array::Command::List;

use strict;
use warnings;

use System;

class System::Disk::Array::Command::List {
    is => 'UR::Object::Command::List',
    has => [
        subject_class_name  => {
            is_constant => 1,
            value => 'System::Disk::Array',
        },
        show => {
            default_value => 'name,model,size',
        },
    ],
};

#sub sub_command_sort_position { 4 }

1;
