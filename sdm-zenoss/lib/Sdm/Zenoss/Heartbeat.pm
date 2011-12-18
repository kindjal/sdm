
package Sdm::Zenoss::Heartbeat;

use Sdm;

class Sdm::Zenoss::Heartbeat {
    schema_name => 'Zenoss',
    data_source => 'Sdm::DataSource::Zenoss',
    table_name => 'heartbeat',
    id_by => {
        device   => { is => 'Text' },
        component => { is => 'Text' }
    },
    has => [
        timeout   => { is => 'Number' },
        lastTime  => { is => 'Timestamp' }
    ]
};

1;
