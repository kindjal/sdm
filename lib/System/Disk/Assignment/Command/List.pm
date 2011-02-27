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
            default_value => 'group_id,volume_id',
        },
    ],
};

sub sub_command_sort_position { 4 }

1;
