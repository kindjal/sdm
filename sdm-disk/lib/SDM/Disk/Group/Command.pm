package SDM::Disk::Group::Command;

use strict;
use warnings;

use SDM;

class SDM::Disk::Group::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk groups',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Disk::Group',
    target_name => 'group',
    list => { show => 'name,subdirectory,unix_uid,unix_gid' },
);

1;
