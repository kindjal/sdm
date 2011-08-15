
package SDM::Zenoss::Device::Command;

use strict;
use warnings;

use SDM;

class SDM::Zenoss::Device::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss Device',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Zenoss::Device',
    target_name => 'device',
    list => { show => 'uid,name,ipaddress' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
