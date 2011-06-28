
package SDM::Service::Lsof::File;

use strict;
use warnings;

use SDM;

class SDM::Service::Lsof::File {
    is => 'SDM::Service::Lsof',
    data_source => 'SDM::DataSource::Service',
    schema_name => 'Service',
    table_name => 'service_lsof_file',
    id_by => [
        id           => { is => 'Integer' },
    ],
    has => [
        filename     => { is => 'Text' },
        hostname     => { is => 'Text' },
        pid          => { is => 'Integer' },
        #process      => { is => 'SDM::Service::Lsof::Process', id_by => ['hostname','pid' ] }
    ],
};

1;
