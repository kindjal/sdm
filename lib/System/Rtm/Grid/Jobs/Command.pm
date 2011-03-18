package System::Rtm::Grid::Jobs::Command;

use strict;
use warnings;

use System;

class System::Rtm::Grid::Jobs::Command {
    is          => 'System::Command::Base',
    doc         => 'work with grid jobs',
    is_abstract => 1
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Rtm::Grid::Jobs',
    target_name => 'jobs',
    list => { show => 'jobid,stat' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
