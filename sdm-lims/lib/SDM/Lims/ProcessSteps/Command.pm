
package SDM::Lims::ProcessSteps::Command;

use SDM;

class SDM::Lims::ProcessSteps::Command {
    is          => 'Command::Tree',
    doc         => 'Work with LIMS ProcessSteps objects',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Lims::ProcessSteps',
    target_name => 'processsteps',
    list => { show => 'ps_id,purpose' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, }
);

1;
