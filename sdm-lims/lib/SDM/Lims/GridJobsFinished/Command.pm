
package SDM::Lims::GridJobsFinished::Command;

use SDM;

class SDM::Lims::GridJobsFinished::Command {
    is          => 'Command::Tree',
    doc         => 'Work with LIMS GridJobsFinished objects',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Lims::GridJobsFinished',
    target_name => 'gridjobsfinished',
    list => { show => 'jobid,bjob_user,stat,exec_host,submit_time,start_time,end_time' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, }
);

1;
