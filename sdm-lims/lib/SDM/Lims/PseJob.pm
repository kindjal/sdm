
package SDM::Lims::PseJob;

use SDM;

class SDM::Lims::PseJob {
    table_name => 'GSC.PSE_JOB',
    data_source => 'SDM::DataSource::Oltp',
    doc         => 'bridge between PSE and JOB',
    id_by => [
        pse_id => { is => 'Number' },
        job_id => { is => 'Number' }
    ],
    has => [
        pse => {
            is => 'SDM::Lims::ProcessStepExecutions',
            id_by => 'pse_id'
        },
        job => {
            is => 'SDM::Lims::GridJobsFinished',
            id_by => 'job_id'
        },
    ]
};

1;
