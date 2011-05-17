package SDM::Rtm::Jobsfinished::Command;

use strict;
use warnings;

use SDM;

class SDM::Rtm::Jobsfinished::Command {
    is          => 'Command::Tree',
    doc         => 'work with finished grid jobs',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Rtm::Jobsfinished',
    target_name => 'jobsfinished',
    list => { show => 'jobid,stat' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
