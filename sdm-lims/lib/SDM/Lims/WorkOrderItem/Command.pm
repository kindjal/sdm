
package SDM::Lims::WorkOrderItem::Command;

use SDM;

class SDM::Lims::WorkOrderItem::Command {
    is          => 'Command::Tree',
    doc         => 'Work with LIMS WorkOrderItem objects',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Lims::WorkOrderItem',
    target_name => 'workorderitem',
    list => { show => 'woi_id,barcode,creation_event_id,dna_id,parent_woi_id,pipeline_id,setup_wo_id,status'},
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, }
);

1;
