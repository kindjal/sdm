package SDM::Service::Automount::Command;

use strict;
use warnings;

use SDM;

class SDM::Service::Automount::Command {
    is          => 'Command::Tree',
    doc         => 'automount config exporter',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Service::Automount',
    target_name => 'automount',
    list   => { show => 'name,mount_options,filername,physical_path' },
    add    => { do_not_init => 1 },
    update => { do_not_init => 1 },
    delete => { do_not_init => 1 },
);


1;
