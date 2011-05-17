package SDM::Disk::Assignment::Command;

use strict;
use warnings;

use SDM;

class SDM::Disk::Assignment::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk assignments',
    is_abstract => 1
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Disk::Assignment',
    target_name => 'assignment',
    list => { show => 'filername,physical_path,group_name' }
);

1;
