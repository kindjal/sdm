package System::Disk::Volume::Command;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command {
    is          => 'System::Command::Base',
    doc         => 'work with disk volumes',
    is_abstract => 1
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Disk::Volume',
    target_name => 'volume',
    list => { show => 'id,mount_path,total_kb,used_kb,disk_group,filername' }
);

1;
