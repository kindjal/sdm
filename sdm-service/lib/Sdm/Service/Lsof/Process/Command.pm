package Sdm::Service::Lsof::Process::Command;

use Sdm;
use strict;
use warnings;

class Sdm::Service::Lsof::Process::Command {
    is          => 'Command::Tree',
    doc         => 'Work with lsof processes',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Service::Lsof::Process',
    target_name => 'process',
    list   => { show => 'hostname,pid,command,username,uid,age' },
    add    => { do_not_init => 1 },
    update => { do_not_init => 1 },
    delete => { do_not_init => 1 },
);

1;
