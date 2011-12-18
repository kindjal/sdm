package Sdm::Disk::ArrayDiskSet::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::ArrayDiskSet::Command {
    is          => 'Command::Tree',
    doc         => 'work with array disk sets',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Disk::ArrayDiskSet',
    target_name => 'array',
    list => { show => 'id,arrayname,disk_num,disk_type,disk_size,capacity,comments' }
);

1;
