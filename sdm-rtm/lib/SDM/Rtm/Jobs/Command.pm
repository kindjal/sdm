package SDM::Rtm::Jobs::Command;

use strict;
use warnings;

use SDM;

class SDM::Rtm::Jobs::Command {
    is          => 'Command::Tree',
    doc         => 'work with grid jobs',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Rtm::Jobs',
    target_name => 'jobs',
    list => { show => 'jobid,stat,jobname,user,cpu_used,efficiency,stime,pend_time,run_time' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
