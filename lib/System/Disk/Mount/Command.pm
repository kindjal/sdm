package System::Disk::Mount::Command;

use strict;
use warnings;

use System;

class System::Disk::Mount::Command {
    #is          => 'System::Command::Base',
    is          => 'Command::Tree',
    doc         => 'work with disk filers',
    #is_abstract => 1
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Mount',
    target_name => 'mount',
    list => { show => 'filername,mount_path,physical_path' }
);

1;
