
package SDM::Lims::WorkOrderItem;

use SDM;

class SDM::Lims::WorOrderItem {
    table_name => 'GSC.WORK_ORDER_ITEM',
    data_source => 'SDM::DataSource::Oltp',
    doc         => 'work with work order items',
    id_by => [
        woi_id => { is => 'Number' }
    ],
    has => [
        creation_event_id => { is => 'Number' },
        setup_wo_id       => { is => 'Number' },
        status            => { is => 'Text' }
    ],
    has_optional => [
        barcode           => { is => 'Text' },
        dna_id            => { is => 'Number' },
        parent_woi_id     => { is => 'Number' },
        pipeline_id       => { is => 'Number' },
        sample            => {
            is => "SDM::Lims::Organism::Sample",
            id_by => 'dna_id'
        }
    ]
};

1;
