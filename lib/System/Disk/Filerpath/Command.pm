package System::Disk::Filerpath::Command;

use strict;
use warnings;

use System;

class System::Disk::Filerpath::Command {
    is          => 'System::Command::Base',
    doc         => 'work with disk filers',
    is_abstract => 1
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Filerpath',
    target_name => 'filerpath',
    list => { show => 'filername,mount_path' }
);

1;
