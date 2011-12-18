
package Sdm::Lims::WorkOrderItem;

use Sdm;

class Sdm::Lims::WorkOrderItem {
    table_name => 'GSC.WORK_ORDER_ITEM',
    data_source => 'Sdm::DataSource::Oltp',
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
            is => "Sdm::Lims::Organism::Sample",
            id_by => 'dna_id'
        },
        individual        => {
            is => "Sdm::Lims::Organism::Individual",
            via => 'sample',
            to => 'individual'
        }
    ],
    has_many_optional => [
        woipse => {
            is => 'Sdm::Lims::WoiPse',
            reverse_as => 'woi'
        },
        pse => {
            is => 'Sdm::Lims::ProcessStepExecutions',
            via => 'woipse',
            to => 'pse'
        }
    ]
};

1;
