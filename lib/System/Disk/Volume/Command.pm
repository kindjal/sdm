package System::Disk::Volume::Command;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk volumes',
    is_abstract => 1
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Volume',
    target_name => 'volume',
    list => { show => 'mount_path,total_kb,used_kb,filername,disk_group' }
);

1;
