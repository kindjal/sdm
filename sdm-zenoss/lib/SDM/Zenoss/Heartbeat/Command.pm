
package SDM::Zenoss::Heartbeat::Command;

use strict;
use warnings;

use SDM;

class SDM::Zenoss::Heartbeat::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss Heartbeat',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Zenoss::Heartbeat',
    target_name => 'heartbeat',
    list => { show => 'device,component,timeout,lastTime' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
