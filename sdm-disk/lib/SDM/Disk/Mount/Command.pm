package SDM::Disk::Mount::Command;

use strict;
use warnings;

use SDM;

class SDM::Disk::Mount::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk filers',
    is_abstract => 1
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Disk::Mount',
    target_name => 'mount',
    list => { show => 'filername,mount_path,physical_path' }
);

1;
