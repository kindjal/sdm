package System::Disk::Array::Command;

use strict;
use warnings;

use System;

class System::Disk::Array::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk arrays',
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Array',
    target_name => 'array',
    list => { show => 'name,type,model,arraysize,hostname' }
);

1;
