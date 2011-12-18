package Sdm::Disk::HostArrayBridge::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::HostArrayBridge::Command {
    is          => 'Command::Tree',
    doc         => 'map hosts to arrays',
    is_abstract => 1
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Disk::HostArrayBridge',
    target_name => 'hostarraybridge',
    list => { show => 'hostname,arrayname' }
);

1;
