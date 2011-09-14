
package SDM::Lims::Organism::Sample::Command;

use SDM;

class SDM::Lims::Organism::Sample::Command {
    is          => 'Command::Tree',
    doc         => 'Work with LIMS Organism::Sample objects',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Lims::Organism::Sample',
    target_name => 'sample',
    list => { show => 'organism_sample_id,cell_type,is_control,nomenclature,common_name,description,full_name,sample_name,sample_type,tissue_label,tissue_name' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, }
);

1;
