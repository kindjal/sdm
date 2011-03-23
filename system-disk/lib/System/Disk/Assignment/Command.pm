package System::Disk::Assignment::Command;

use strict;
use warnings;

use System;

class System::Disk::Assignment::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk assignments',
    is_abstract => 1
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Assignment',
    target_name => 'assignment',
    list => { show => 'filername,physical_path,group_name' }
);

1;
