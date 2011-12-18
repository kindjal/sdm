package Sdm::Service::Lsof::File::Command;

use Sdm;
use strict;
use warnings;

class Sdm::Service::Lsof::File::Command {
    is          => 'Command::Tree',
    doc         => 'Work with lsof files',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Service::Lsof::File',
    target_name => 'file',
    list   => { show => 'hostname,pid,filename' },
    add    => { do_not_init => 1 },
    update => { do_not_init => 1 },
    delete => { do_not_init => 1 },
);

1;
