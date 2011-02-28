package System::Disk::Filer::Command::List;

use strict;
use warnings;

use System;

class System::Disk::Filer::Command::List {
    is => 'UR::Object::Command::List',
    has => [
        subject_class_name  => {
            is_constant => 1,
            value => 'System::Disk::Filer',
        },
        show => { 
            default_value => 'name,filesystem,status,comments' 
        },
    ],
};

1;
