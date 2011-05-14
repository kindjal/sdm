package SDM::Disk::HostArrayBridge::Command;

use strict;
use warnings;

use SDM;

class SDM::Disk::HostArrayBridge::Command {
    is          => 'Command::Tree',
    doc         => 'map hosts to arrays',
    is_abstract => 1
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Disk::HostArrayBridge',
    target_name => 'hostarraybridge',
    list => { show => 'hostname,arrayname' }
);

1;
