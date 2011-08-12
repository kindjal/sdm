
package SDM::Zenoss::Heartbeat;

use SDM;

class SDM::Zenoss::Heartbeat {
    schema_name => 'Zenoss',
    data_source => 'SDM::DataSource::Zenoss',
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
