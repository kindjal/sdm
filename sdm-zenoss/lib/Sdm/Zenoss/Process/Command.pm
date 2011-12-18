
package Sdm::Zenoss::Process::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Zenoss::Process::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss Process',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Zenoss::Process',
    target_name => 'process',
    list => { show => 'uid,name,status' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
