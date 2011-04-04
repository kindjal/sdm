package System::Disk::Group::Command;

use strict;
use warnings;

use System;

class System::Disk::Group::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk groups',
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Group',
    target_name => 'group',
    list => { show => 'name,subdirectory,unix_uid,unix_gid' },
);

1;
