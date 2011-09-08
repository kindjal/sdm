package SDM::Rtm::Host::Command;

use strict;
use warnings;

use SDM;

class SDM::Rtm::Host::Command {
    is          => 'Command::Tree',
    doc         => 'work with RTM hosts',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Rtm::Host',
    target_name => 'host',
    list => { show => 'host,status,hCtrlMsg,maxJobs,numJobs,numRun' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
