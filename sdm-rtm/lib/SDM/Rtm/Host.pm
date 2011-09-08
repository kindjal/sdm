package SDM::Rtm::Host;

use strict;
use warnings;

use SDM;

class SDM::Rtm::Host {
    table_name => 'grid_hosts',
    schema_name => 'Rtm',
    data_source => 'SDM::DataSource::Rtm',
    doc         => 'work with grid jobs',
    id_by => [
        host        => { is => 'Text' },
        clusterid   => { is => 'Number' },
    ],
    has => [
        status      => { is => 'Text' },
        prev_status => { is => 'Text' },
        hStatus       => { is => 'Number', default_value => 0 },
        hCtrlMsg      => { is => 'Text', default_value => '' },
        time_in_state => { is => 'Number', default_value => 0 },
        cpuFactor     => { is => 'Text', default_value => '' },
        windows       => { is => 'Text', default_value => '' },
        userJobLimit  => { is => 'Text', default_value => '' },
        maxJobs       => { is => 'Number', default_value => 0 },
        numJobs       => { is => 'Number', default_value => 0 },
        numRun        => { is => 'Number', default_value => 0 },
        numSSUSP      => { is => 'Number', default_value => 0 },
        numUSUSP      => { is => 'Number', default_value => 0 },
        mig           => { is => 'Number', default_value => 0 },
        attr          => { is => 'Number', default_value => 0 },
        numRESERVE    => { is => 'Number', default_value => 0 },
        present       => { is => 'Number', default_value => 0 },
        exceptional   => { is => 'Number', default_value => 0 },
    ],
    has_many_optional => [
        jobs => {
            is => "SDM::Rtm::Jobs",
            reverse_as => "host"
        }
    ]
};

1;
