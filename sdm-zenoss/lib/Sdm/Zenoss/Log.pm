
package Sdm::Zenoss::Log;

use Sdm;

class Sdm::Zenoss::Log {
    schema_name => 'Zenoss',
    data_source => 'Sdm::DataSource::Zenoss',
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
