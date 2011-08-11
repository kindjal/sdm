
package SDM::Zenoss::History::Command;

use strict;
use warnings;

use SDM;

class SDM::Zenoss::History::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss History',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Zenoss::History',
    target_name => 'history',
    list => { show => 'evid,device,summary' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
