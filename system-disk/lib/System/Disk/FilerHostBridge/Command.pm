package System::Disk::FilerHostBridge::Command;

use strict;
use warnings;

use System;

class System::Disk::FilerHostBridge::Command {
    is          => 'System::Command::Base',
    doc         => 'map filers to hosts',
    is_abstract => 1
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::FilerHostBridge',
    target_name => 'filerhostbridge',
    list => { show => 'filername,hostname' }
);

1;
