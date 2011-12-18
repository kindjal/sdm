package Sdm::Disk::Volume::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Volume::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk volumes',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Disk::Volume',
    target_name => 'volume',
    list => { show => 'id,physical_path,mount_path,filername,total_kb,used_kb,disk_group,hostname,arrayname' }
);

1;
