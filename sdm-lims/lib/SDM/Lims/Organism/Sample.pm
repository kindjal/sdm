
package SDM::Lims::Organism::Sample;

use SDM;

class SDM::Lims::Organism::Sample {
    table_name => 'GSC.ORGANISM_SAMPLE',
    schema_name => 'GMSchema',
    data_source => 'SDM::DataSource::GMSchema',
    doc         => 'work with organism samples',
    id_by => [
        organism_sample_id => { is => 'Number' }
    ],
    has => [
        cell_type => { is => 'Text' },
        is_control => { is => 'Number' },
        nomenclature => { is => 'Varchar' }
    ],
    has_optional => [
        arrival_date                => { is => 'Date' },
        common_name                 => { is => 'Text' },
        confirm_ext_genotype_seq_id => { is => 'Number' },
        default_genotype_seq_id     => { is => 'Number' },
        description                 => { is => 'Text' },
        dna_provider_id             => { is => 'Number' },
        full_name                   => { is => 'Text' },
        gender                      => { is => 'Text' },
        general_research_consent    => { is => 'Number' },
        is_protected_access         => { is => 'Number' },
        is_ready_for_analysis       => { is => 'Number' },
        organ_name                  => { is => 'Text' },
        reference_sequence_set_id   => { is => 'Number' },
        sample_name                 => { is => 'Text' },
        sample_type                 => { is => 'Text' },
        source_id                   => { is => 'Number' },
        source_type                 => { is => 'Text' },
        taxon_id                    => { is => 'Number' },
        tissue_label                => { is => 'Text' },
        tissue_name                 => { is => 'Text' }
    ]
};

1;
