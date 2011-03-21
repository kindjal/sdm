package System::Disk::HostArrayBridge::Command;

use strict;
use warnings;

use System;

class System::Disk::HostArrayBridge::Command {
    is          => 'System::Command::Base',
    doc         => 'map hosts to arrays',
    is_abstract => 1
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::HostArrayBridge',
    target_name => 'hostarraybridge',
    list => { show => 'hostname,arrayname' }
);

1;
