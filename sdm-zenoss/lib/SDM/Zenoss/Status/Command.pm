
package SDM::Zenoss::Status::Command;

use strict;
use warnings;

use SDM;

class SDM::Zenoss::Status::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss Status',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Zenoss::Status',
    target_name => 'status',
    list => { show => 'evid,device,summary' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
