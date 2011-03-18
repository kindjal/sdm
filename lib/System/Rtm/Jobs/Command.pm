package System::Rtm::Jobs::Command;

use strict;
use warnings;

use System;

class System::Rtm::Jobs::Command {
    is          => 'System::Command::Base',
    doc         => 'work with grid jobs',
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Rtm::Jobs',
    target_name => 'jobs',
    list => { show => 'jobid,stat,jobname,user,cpu_used,efficiency,stime,pend_time,run_time' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
