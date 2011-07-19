package SDM::Service::Lsof::File::Command;

use SDM;
use strict;
use warnings;

class SDM::Service::Lsof::File::Command {
    is          => 'Command::Tree',
    doc         => 'Work with lsof files',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Service::Lsof::File',
    target_name => 'file',
    list   => { show => 'hostname,pid,filename' },
    add    => { do_not_init => 1 },
    update => { do_not_init => 1 },
    delete => { do_not_init => 1 },
);

1;
