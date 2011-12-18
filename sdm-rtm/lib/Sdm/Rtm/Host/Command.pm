package Sdm::Rtm::Host::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Rtm::Host::Command {
    is          => 'Command::Tree',
    doc         => 'work with RTM hosts',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Rtm::Host',
    target_name => 'host',
    list => { show => 'host,status,hCtrlMsg,maxJobs,numJobs,numRun' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
