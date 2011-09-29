
package SDM::Disk::PolyserveVolume;

use strict;
use warnings;

use SDM;
use Date::Manip;

=head2 SDM::Disk::PolyserveVolume
Polyserve volumes have UNIQUE(name) vs. normal volumes which are UNIQUE(name,filername)
=cut
class SDM::Disk::PolyserveVolume {
    table_name => 'disk_polyserve_volume',
    is => 'SDM::Disk::Volume',
    schema_name => 'Disk',
    data_source => 'SDM::DataSource::Disk',
    id_generator => '-uuid',
    id_by => [
        id => { is => 'Text' }
    ],
};

1;
