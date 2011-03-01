package System::Disk::Host::Command::List;

use strict;
use warnings;

use System;

class System::Disk::Host::Command::List {
    is => 'UR::Object::Command::List',
    has => [
        subject_class_name  => {
            is_constant => 1,
            value => 'System::Disk::Host',
        },
        show => {
            default_value => 'hostname,filername,os,status'
        },
    ],
};

1;
