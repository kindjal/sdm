package SDM::Disk::Volume::Command;

use strict;
use warnings;

use SDM;

class SDM::Disk::Volume::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk volumes',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Disk::Volume',
    target_name => 'volume',
    list => { show => 'id,physical_path,mount_path,filername,total_kb,used_kb,disk_group,hostname,arrayname' }
);

1;
