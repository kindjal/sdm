
package Sdm::Zenoss::Service::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Zenoss::Service::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss Service',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Zenoss::Service',
    target_name => 'service',
    list => { show => 'uid,name,status' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
