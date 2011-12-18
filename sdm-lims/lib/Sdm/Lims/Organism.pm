
package Sdm::Lims::Organism;

use Sdm;

class Sdm::Lims::Organism {
    table_name => 'ORGANISM',
    schema_name => 'Oltp',
    data_source => 'Sdm::DataSource::Oltp',
    doc         => 'work with organisms',
    id_by => [
        org_id => { is => 'Number' }
    ],
    has => [
        organism_name => { is => 'Text' }
    ],
    has_optional => [
        current_default_org_prefix => { is => 'Text' },
        latin_name                 => { is => 'Text' },
        organism_genome_size       => { is => 'Number' },
        strain                     => { is => 'Text' }
    ]
};

1;
