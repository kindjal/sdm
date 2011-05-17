package SDM::Disk::Export::Command;

use strict;
use warnings;

use SDM;

class SDM::Disk::Export::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk exports',
    is_abstract => 1
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Disk::Export',
    target_name => 'export',
    list => { show => 'id,filername,physical_path' }
);

1;
