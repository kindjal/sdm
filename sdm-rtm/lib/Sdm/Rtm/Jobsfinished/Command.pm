package Sdm::Rtm::Jobsfinished::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Rtm::Jobsfinished::Command {
    is          => 'Command::Tree',
    doc         => 'work with finished grid jobs',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Rtm::Jobsfinished',
    target_name => 'jobsfinished',
    list => { show => 'jobid,stat' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
