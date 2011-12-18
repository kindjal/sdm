
package Sdm::Zenoss::AlertState;

use Sdm;

class Sdm::Zenoss::AlertState {
    schema_name => 'Zenoss',
    data_source => 'Sdm::DataSource::Zenoss',
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
