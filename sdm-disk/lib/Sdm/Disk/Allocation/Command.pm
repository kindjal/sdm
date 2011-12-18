package Sdm::Disk::Allocation::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Allocation::Command {
    is  => 'Command::Tree',
    doc => 'work with disk allocations',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Disk::Allocation',
    target_name => 'allocations',
    #list => { show => 'mount_path,allocation_path,kilobytes_requested,owner' },
    list => { show => 'mount_path,allocation_path,kilobytes_requested' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
