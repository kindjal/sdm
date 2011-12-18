package Sdm::Disk::Array::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Array::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk arrays',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Disk::Array',
    target_name => 'array',
    list => { show => 'name,manufacturer,model,arraysize,comments,disk_set_num' }
);

1;
