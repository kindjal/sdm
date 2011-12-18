
package Sdm::Zenoss::History::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Zenoss::History::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss History',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Zenoss::History',
    target_name => 'history',
    list => { show => 'evid,device,summary' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
