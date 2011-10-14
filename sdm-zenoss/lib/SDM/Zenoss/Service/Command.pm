
package SDM::Zenoss::Service::Command;

use strict;
use warnings;

use SDM;

class SDM::Zenoss::Service::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss Service',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Zenoss::Service',
    target_name => 'service',
    list => { show => 'uid,name,status' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
