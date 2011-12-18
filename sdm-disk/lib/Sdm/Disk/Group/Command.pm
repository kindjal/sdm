package Sdm::Disk::Group::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Group::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk groups',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Disk::Group',
    target_name => 'group',
    list => { show => 'name,subdirectory,unix_uid,unix_gid' },
);

1;
