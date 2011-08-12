
package SDM::Zenoss::Detail::Command;

use strict;
use warnings;

use SDM;

class SDM::Zenoss::Detail::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss Detail',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Zenoss::Detail',
    target_name => 'detail',
    list => { show => 'evid,sequence,name,value' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
