package System::Disk::User::Command::List;

use strict;
use warnings;

use System;

class System::Disk::User::Command::List {
    is => 'UR::Object::Command::List',
    has => [
        subject_class_name  => {
            is_constant => 1,
            value => 'System::Disk::User',
        },
        show => { 
            default_value => 'email',
        },
    ],
};

1;
