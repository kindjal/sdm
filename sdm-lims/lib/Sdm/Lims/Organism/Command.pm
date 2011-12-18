
package Sdm::Lims::Organism::Command;

use Sdm;

class Sdm::Lims::Organism::Command {
    is          => 'Command::Tree',
    doc         => 'Work with LIMS Organisms objects',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Lims::Organism',
    target_name => 'organisms',
    list => { show => 'org_id,organism_name,current_default_org_prefix,latin_name,organism_genome_size,strain' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, }
);

1;
