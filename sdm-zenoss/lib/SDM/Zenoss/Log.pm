
package SDM::Zenoss::Log;

use SDM;

class SDM::Zenoss::Log {
    schema_name => 'Zenoss',
    data_source => 'SDM::DataSource::Zenoss',
    table_name => 'log',
    id_by => {
        evid  => { is => 'Text' }
    },
    has => [
        userName => { is => 'Text' },
        ctime    => { is => 'Timestamp' },
        text     => { is => 'Text' }
    ]
};

1;
