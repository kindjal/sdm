package System::Disk::Host::Command;

use strict;
use warnings;

use System;

class System::Disk::Host::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk hosts',
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Host',
    target_name => 'host',
    list => { show => 'hostname,filername,arrayname,os,location,status,comments' }
);

1;
