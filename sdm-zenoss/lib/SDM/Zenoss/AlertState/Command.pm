
package SDM::Zenoss::AlertState::Command;

use strict;
use warnings;

use SDM;

class SDM::Zenoss::AlertState::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss AlertState',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Zenoss::AlertState',
    target_name => 'alert_state',
    list => { show => 'evid,userid,rule,lastSent' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
