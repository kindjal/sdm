
package Sdm::Lims::GridJobsFinished::Command;

use Sdm;

class Sdm::Lims::GridJobsFinished::Command {
    is          => 'Command::Tree',
    doc         => 'Work with LIMS GridJobsFinished objects',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Lims::GridJobsFinished',
    target_name => 'gridjobsfinished',
    list => { show => 'jobid,bjob_user,stat,exec_host,submit_time,start_time,end_time' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, }
);

1;
