
package SDM::Lims::Organism::Individual;

use SDM;

class SDM::Lims::Organism::Individual {
    table_name => 'GSC.ORGANISM_INDIVIDUAL',
    schema_name => 'GMSchema',
    data_source => 'SDM::DataSource::GMSchema',
    doc         => 'work with organism individuals',
    id_by => [
        organism_id => { is => 'Number' }
    ],
    has => [
        taxon_id    => { is => 'Number' }
    ],
    has_optional => [
        common_name     => { is => 'Text' },
        description     => { is => 'Text' },
        ethnicity       => { is => 'Text' },
        father_id       => { is => 'Number' },
        full_name       => { is => 'Text' },
        gender          => { is => 'Text' },
        mother_id       => { is => 'Number' },
        name            => { is => 'Text' },
        nomenclature    => { is => 'Text' },
        participant_id  => { is => 'Text' },
        race            => { is => 'Text' }
    ]
};

1;
