package SDM::Disk::Array::Command;

use strict;
use warnings;

use SDM;

class SDM::Disk::Array::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk arrays',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Disk::Array',
    target_name => 'array',
    list => { show => 'name,type,model,arraysize,hostname' }
);

1;
