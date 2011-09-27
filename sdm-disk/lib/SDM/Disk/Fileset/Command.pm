package SDM::Disk::Fileset::Command;

use strict;
use warnings;

use SDM;

class SDM::Disk::Fileset::Command {
    is          => 'Command::Tree',
    doc         => 'work with disk filesets',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Disk::Fileset',
    target_name => 'volume',
    list => { show => 'name,kb_size,kb_quota,kb_limit,kb_in_doubt,kb_grace,files,file_quota,file_limit,file_grace' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
