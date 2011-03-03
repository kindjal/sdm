package System::Disk::Filer::Command;

use strict;
use warnings;

use System;

class System::Disk::Filer::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk users',
    is_abstract => 1
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Filer',
    target_name => 'filer',
    list => { show => 'name,status,comments' }
);

1;
