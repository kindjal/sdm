package System::Disk::Group::Command;

use strict;
use warnings;

use System;

class System::Disk::Group::Command {
    is          => 'System::Command::Base',
    doc         => 'work with disk groups',
    is_abstract => 1,
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Group',
    target_name => 'group',
    list => { show => 'name,subdirectory,username,unix_uid,unix_gid' },
);

1;
