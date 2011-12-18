
package Sdm::Lims::Organism::Individual::Command;

use Sdm;

class Sdm::Lims::Organism::Individual::Command {
    is          => 'Command::Tree',
    doc         => 'Work with LIMS Organism::Individual objects',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Lims::Organism::Individual',
    target_name => 'individual',
    list => { show => 'organism_id,taxon_id,common_name,description,ethnicity,father_id,full_name,gender,mother_id,name,nomenclature,participant_id,race' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, }
);

1;
