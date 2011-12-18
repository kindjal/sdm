
package Sdm::Zenoss::Heartbeat::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Zenoss::Heartbeat::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss Heartbeat',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Zenoss::Heartbeat',
    target_name => 'heartbeat',
    list => { show => 'device,component,timeout,lastTime' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
