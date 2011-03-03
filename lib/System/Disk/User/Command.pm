package System::Disk::User::Command;

use strict;
use warnings;

use System;

class System::Disk::User::Command {
    is          => 'Command',
    doc         => 'work with disk users',
    is_abstract => 1,
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::User',
    target_name => 'user',
    list => { show => 'email', },
    update => { only_if_null => 1, },
    delete => { do_not_init => 1, },
);

1;
