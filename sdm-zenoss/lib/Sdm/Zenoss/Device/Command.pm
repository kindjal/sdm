
package Sdm::Zenoss::Device::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Zenoss::Device::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Zenoss Device',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Zenoss::Device',
    target_name => 'device',
    list => { show => 'name,ipaddress,deviceclass,productionstate,hwmanufacturer,hwmodel,osmodel' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
