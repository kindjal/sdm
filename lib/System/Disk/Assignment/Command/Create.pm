package System::Disk::Assignment::Command::Create;

use strict;
use warnings;

use System;

class System::Disk::Assignment::Command::Create {
    is => 'System::Command::Base',
    has => [
        subject_class_name  => {
            is_constant => 1,
            value => 'System::Disk::Assignment',
        },
        show => {
            default_value => 'name,volume',
        },
    ],
};

1;
