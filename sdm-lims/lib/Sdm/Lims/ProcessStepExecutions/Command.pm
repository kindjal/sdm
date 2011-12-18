
package Sdm::Lims::ProcessStepExecutions::Command;

use Sdm;

class Sdm::Lims::ProcessStepExecutions::Command {
    is          => 'Command::Tree',
    doc         => 'Work with LIMS ProcessStepExecution objects',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Lims::ProcessStepExecutions',
    target_name => 'pse',
    list => { show => 'pse_id,date_scheduled,ei_ei_id,ps_ps_id,pse_session,psesta_pse_status,date_completed,ei_ei_id_confirm,pipe,prior_pse_id,pr_pse_result,tp_id' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, }
);

1;
