package Sdm::Service::Automount::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Service::Automount::Command {
    is          => 'Command::Tree',
    doc         => 'automount config exporter',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Service::Automount',
    target_name => 'automount',
    list   => { show => 'name,mount_options,filername,physical_path' },
    add    => { do_not_init => 1 },
    update => { do_not_init => 1 },
    delete => { do_not_init => 1 },
);


1;
