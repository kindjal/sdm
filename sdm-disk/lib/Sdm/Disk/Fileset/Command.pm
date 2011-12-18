package Sdm::Disk::Fileset::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Fileset::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk filesets',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Disk::Fileset',
    target_name => 'fileset',
    list => { show => 'id,physical_path,mount_path,kb_size,kb_quota,kb_limit,kb_in_doubt,kb_grace,files,file_quota,file_limit,file_grace' },
);

1;
