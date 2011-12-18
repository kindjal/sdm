
package Sdm::Zenoss::Status;

use Sdm;

class Sdm::Zenoss::Status{
    schema_name => 'Zenoss',
    data_source => 'Sdm::DataSource::Zenoss',
    table_name => 'status',
    id_by => {
        evid  => { is => 'Text' }
    },
    has => [
        dedupid           => { is => 'Text' },
        device            => { is => 'Text' },
        component         => { is => 'Text' },
        eventClass        => { is => 'Text' },
        eventKey          => { is => 'Text' },
        summary           => { is => 'Text' },
        message           => { is => 'Text' },
        severity          => { is => 'Number' },
        eventState        => { is => 'Number' },
        eventClassKey     => { is => 'Text' },
        eventGroup        => { is => 'Text' },
        stateChange       => { is => 'Timestamp' },
        firstTime         => { is => 'Number' },
        lastTime          => { is => 'Number' },
        count             => { is => 'Number' },
        prodState         => { is => 'Number' },
        suppid            => { is => 'Text' },
        manager           => { is => 'Text' },
        agent             => { is => 'Text' },
        DeviceClass       => { is => 'Text' },
        Location          => { is => 'Text' },
        Systems           => { is => 'Text' },
        DeviceGroups      => { is => 'Text' },
        ipAddress         => { is => 'Text' },
        facility          => { is => 'Text' },
        priority          => { is => 'Number' },
        ntevid            => { is => 'Number' },
        ownerid           => { is => 'Text' },
        clearid           => { is => 'Text' },
        DevicePriority    => { is => 'Number' },
        eventClassMapping => { is => 'Text' },
        monitor           => { is => 'Text' },
    ]
};

1;
