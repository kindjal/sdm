package System::Disk::Array::Command;

use strict;
use warnings;

use System;

class System::Disk::Array::Command {
    is          => 'System::Command::Base',
    doc         => 'work with disk arrays',
    is_abstract => 1
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Array',
    target_name => 'array',
    list => { show => 'name,type,model,size,hostname' }
    #list => { show => 'name,type,model,size' }
);

1;