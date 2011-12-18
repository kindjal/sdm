package Sdm::Rtm::Jobs::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Rtm::Jobs::Command {
    is          => 'Command::Tree',
    doc         => 'work with grid jobs',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Rtm::Jobs',
    target_name => 'jobs',
    list => { show => 'jobid,stat,jobname,user,cpu_used,efficiency,stime,pend_time,run_time' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
