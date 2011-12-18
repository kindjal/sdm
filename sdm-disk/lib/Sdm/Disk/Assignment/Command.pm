package Sdm::Disk::Assignment::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Assignment::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk assignments',
    is_abstract => 1
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Disk::Assignment',
    target_name => 'assignment',
    list => { show => 'filername,physical_path,group_name' }
);

1;
