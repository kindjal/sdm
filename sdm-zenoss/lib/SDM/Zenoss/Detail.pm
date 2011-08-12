
package SDM::Zenoss::Detail;

use SDM;

class SDM::Zenoss::Detail {
    schema_name => 'Zenoss',
    data_source => 'SDM::DataSource::Zenoss',
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
