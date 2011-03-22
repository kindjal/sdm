package System::Rtm::Jobsfinished::Command;

use strict;
use warnings;

use System;

class System::Rtm::Jobsfinished::Command {
    is          => 'System::Command::Base',
    doc         => 'work with finished grid jobs',
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Rtm::Jobsfinished',
    target_name => 'jobsfinished',
    list => { show => 'jobid,stat' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
