
package SDM::Zenoss::Log::Command;

use strict;
use warnings;

use SDM;

class SDM::Zenoss::Log::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss Log',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Zenoss::Log',
    target_name => 'log',
    list => { show => 'evid,userName,ctime,text' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
