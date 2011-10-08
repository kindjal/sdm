package SDM::Disk::Filer::Command;

use strict;
use warnings;

use SDM;

class SDM::Disk::Filer::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk filers',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Disk::Filer',
    target_name => 'filer',
    list => { show => 'name,status,hostname,arrayname,comments' }
);

1;
