
package Sdm::Zenoss::Detail;

use Sdm;

class Sdm::Zenoss::Detail {
    schema_name => 'Zenoss',
    data_source => 'Sdm::DataSource::Zenoss',
    table_name => 'detail',
    id_by => {
        evid  => { is => 'Text' }
    },
    has => [
        sequence => { is => 'Number' },
        name     => { is => 'Text' },
        value    => { is => 'Text' }
    ]
};

1;
