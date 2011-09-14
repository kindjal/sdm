
package SDM::Lims::Organism::Individual::Command;

use SDM;

class SDM::Lims::Organism::Individual::Command {
    is          => 'Command::Tree',
    doc         => 'Work with LIMS Organism::Individual objects',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Lims::Organism::Individual',
    target_name => 'individual',
    list => { show => 'organism_id,taxon_id,common_name,description,ethnicity,father_id,full_name,gender,mother_id,name,nomenclature,participant_id,race' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, }
);

1;
