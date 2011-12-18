
package Sdm::Lims::ProcessSteps::Command;

use Sdm;

class Sdm::Lims::ProcessSteps::Command {
    is          => 'Command::Tree',
    doc         => 'Work with LIMS ProcessSteps objects',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Lims::ProcessSteps',
    target_name => 'processsteps',
    list => { show => 'ps_id,purpose' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, }
);

1;
