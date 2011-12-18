
package Sdm::Lims::WoiPse;

use Sdm;

class Sdm::Lims::WoiPse {
    table_name => 'GSC.WOI_PSE',
    data_source => 'Sdm::DataSource::Oltp',
    doc         => 'bridge between WOI and PSE',
    id_by => [
        dl_id  => { is => 'Number' },
        pse_id => { is => 'Number' },
        woi_id => { is => 'Number' }
    ],
    has => [
        pse => {
            is => 'Sdm::Lims::ProcessStepExecutions',
            id_by => 'pse_id'
        },
        woi => {
            is => 'Sdm::Lims::WorkOrderItem',
            id_by => 'woi_id'
        },
    ]
};

1;
