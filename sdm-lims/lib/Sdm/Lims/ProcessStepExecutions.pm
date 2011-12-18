
package Sdm::Lims::ProcessStepExecutions;

use Sdm;

class Sdm::Lims::ProcessStepExecutions {
    table_name => 'GSC.PROCESS_STEP_EXECUTIONS',
    data_source => 'Sdm::DataSource::Oltp',
    doc         => 'work with process step executions',
    id_by => [
        pse_id => { is => 'Number' }
    ],
    has => [
        date_scheduled => { is => 'Date' },
        ei_ei_id          => { is => 'Number' },
        ps_ps_id       => { is => 'Number' },
        pse_session    => { is => 'Number' },
        psesta_pse_status     => { is => 'Text' }
    ],
    has_optional => [
        date_completed => { is => 'Date' },
        ei_ei_id_confirm  => { is => 'Number' },
        pipe           => { is => 'Number' },
        prior_pse_id   => { is => 'Number' },
        pr_pse_result  => { is => 'Text' },
        tp_id          => { is => 'Number' },
        step => {
            is => 'Sdm::Lims::ProcessSteps',
            id_by => 'ps_ps_id'
        }
    ],
    has_many_optional => [
        woipse => {
            is => 'Sdm::Lims::WoiPse',
            reverse_as => 'pse'
        },
        woi => {
            is => 'Sdm::Lims::WorkOrderItem',
            via => 'woipse',
            to => 'woi'
        },
        psejob => {
            is => 'Sdm::Lims::PseJob',
            reverse_as => 'pse'
        },
        job => {
            is => 'Sdm::Lims::GridJobsFinished',
            via => 'psejob',
            to => 'job'
        }
    ]
};

1;
