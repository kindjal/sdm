package System::Disk::Export::Command;

use strict;
use warnings;

use System;

class System::Disk::Export::Command {
    #is          => 'System::Command::Base',
    is          => 'Command::Tree',
    doc         => 'work with disk filers',
    #is_abstract => 1
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Export',
    target_name => 'export',
    list => { show => 'id,filername,physical_path' }
);

1;
