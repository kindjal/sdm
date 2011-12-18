
package Sdm::Lims::ProcessSteps;

use Sdm;

class Sdm::Lims::ProcessSteps {
    table_name => 'GSC.PROCESS_STEPS',
    data_source => 'Sdm::DataSource::Oltp',
    doc         => 'work with process steps',
    id_by => [
        ps_id  => { is => 'Number' },
    ],
    has => [
        archive_number_status       => { is => 'Text' },
        barcode_input_status        => { is => 'Text' },
        barcode_output_status       => { is => 'Text' },
        bp_barcode_prefix           => { is => 'Text' },
        bp_barcode_prefix_input     => { is => 'Text' },
        completed_prior_pse         => { is => 'Number' },
        data_status                 => { is => 'Text' },
        force_work_order_selection  => { is => 'Number' },
        gro_group_name              => { is => 'Text' },
        manual_confirmation         => { is => 'Text' },
        output_device               => { is => 'Text' },
        prodir_process_direction    => { is => 'Text' },
        pss_process_step_status     => { is => 'Text' },
        pro_process_to              => { is => 'Text' },
        purpose                     => { is => 'Text' },
        purpose_order               => { is => 'Number' },
        subclone_status             => { is => 'Text' },
        work_order_required         => { is => 'Number' },
    ],
    has_optional => [
        create_entity_type_name   => { is => 'Text' },
        group_id                  => { is => 'Number' },
        next_sched_flag           => { is => 'Number' },
        psp_path_tag              => { is => 'Text' },
        prior_process_method_type => { is => 'Text' },
        pro_process               => { is => 'Text' },
        process_id                => { is => 'Number' },
        purpose_id                => { is => 'Number' },
    ],
};

1;
