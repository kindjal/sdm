package SDM::Disk::ArrayDiskSet::Command;

use strict;
use warnings;

use SDM;

class SDM::Disk::ArrayDiskSet::Command {
    is          => 'Command::Tree',
    doc         => 'work with array disk sets',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Disk::ArrayDiskSet',
    target_name => 'array',
    list => { show => 'id,arrayname,disk_num,disk_type,disk_size,capacity,comments' }
);

1;
