
package Sdm::Zenoss::Status::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Zenoss::Status::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss Status',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Zenoss::Status',
    target_name => 'status',
    list => { show => 'evid,device,summary' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
