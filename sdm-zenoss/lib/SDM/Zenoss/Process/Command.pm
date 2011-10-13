
package SDM::Zenoss::Process::Command;

use strict;
use warnings;

use SDM;

class SDM::Zenoss::Process::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss Process',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Zenoss::Process',
    target_name => 'process',
    list => { show => 'uid,name,status' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
