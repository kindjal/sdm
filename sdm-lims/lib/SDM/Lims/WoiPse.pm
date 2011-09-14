
package SDM::Lims::WoiPse;

use SDM;

class SDM::Lims::WoiPse {
    table_name => 'GSC.WOI_PSE',
    data_source => 'SDM::DataSource::Oltp',
    doc         => 'bridge between WOI and PSE',
    id_by => [
        dl_id  => { is => 'Number' },
        pse_id => { is => 'Number' },
        woi_id => { is => 'Number' }
    ],
    has => [
        pse => {
            is => 'SDM::Lims::ProcessStepExecutions',
            id_by => 'pse_id'
        },
        woi => {
            is => 'SDM::Lims::WorkOrderItem',
            id_by => 'woi_id'
        },
    ]
};

1;
