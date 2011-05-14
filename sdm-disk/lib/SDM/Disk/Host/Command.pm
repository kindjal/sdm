package SDM::Disk::Host::Command;

use strict;
use warnings;

use SDM;

class SDM::Disk::Host::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk hosts',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Disk::Host',
    target_name => 'host',
    list => { show => 'hostname,filername,arrayname,os,location,status,comments' }
);

1;
