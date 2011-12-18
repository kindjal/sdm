
package Sdm::Lims::PseJob;

use Sdm;

class Sdm::Lims::PseJob {
    table_name => 'GSC.PSE_JOB',
    data_source => 'Sdm::DataSource::Oltp',
    doc         => 'bridge between PSE and JOB',
    id_by => [
        pse_id => { is => 'Number' },
        job_id => { is => 'Number' }
    ],
    has => [
        pse => {
            is => 'Sdm::Lims::ProcessStepExecutions',
            id_by => 'pse_id'
        },
        job => {
            is => 'Sdm::Lims::GridJobsFinished',
            id_by => 'job_id'
        },
    ]
};

1;
