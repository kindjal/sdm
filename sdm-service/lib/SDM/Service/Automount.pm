
package SDM::Service::Automount;

use strict;
use warnings;

use SDM;

class SDM::Service::Automount {
    data_source => 'SDM::DataSource::Automount',
    schema_name => 'Automount',
    table_name => 'service_automount',
    id_by => [
        name => { is => 'Text' },
    ],
    has => [
        mount_options => { is => 'Text' },
        filername     => { is => 'Text' },
        physical_path => { is => 'Text' },
    ],
};

1;
