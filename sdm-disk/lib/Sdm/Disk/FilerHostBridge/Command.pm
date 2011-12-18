package Sdm::Disk::FilerHostBridge::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::FilerHostBridge::Command {
    is          => 'Command::Tree',
    doc         => 'map filers to hosts',
    is_abstract => 1
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Disk::FilerHostBridge',
    target_name => 'filerhostbridge',
    list => { show => 'filername,hostname' }
);

1;
