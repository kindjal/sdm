package System::Disk::Volume::Command;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk volumes',
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Volume',
    target_name => 'volume',
    list => { show => 'id,mount_path,total_kb,used_kb,disk_group,filername' }
);

1;
