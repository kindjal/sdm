package SDM::Disk::FilerHostBridge::Command;

use strict;
use warnings;

use SDM;

class SDM::Disk::FilerHostBridge::Command {
    is          => 'Command::Tree',
    doc         => 'map filers to hosts',
    is_abstract => 1
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Disk::FilerHostBridge',
    target_name => 'filerhostbridge',
    list => { show => 'filername,hostname' }
);

1;
