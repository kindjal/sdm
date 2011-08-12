
package SDM::Zenoss::AlertState;

use SDM;

class SDM::Zenoss::AlertState {
    schema_name => 'Zenoss',
    data_source => 'SDM::DataSource::Zenoss',
    table_name => 'alert_state',
    id_by => {
        evid  => { is => 'Text' }
    },
    has => [
        userid   => { is => 'Text' },
        rule     => { is => 'Text' },
        lastSent => { is => 'Timestamp' }
    ]
};

1;
