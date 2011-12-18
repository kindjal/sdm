
package Sdm::Disk::ArrayDiskSet;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::ArrayDiskSet {
    table_name => 'disk_array_disk_set',
    id_by => [
        id => { is => 'Number' },
    ],
    has => [
        arrayname          => { is => 'Text' },
        array              => { is => 'Sdm::Disk::Array', id_by => 'arrayname' },
        disk_type          => { is => 'Text' },
        disk_num           => { is => 'Integer', default_value => 0 },
        disk_size          => { is => 'Integer', default_value => 0 },
        capacity           => {
            is => 'Integer',
            calculate_from => [ 'disk_num', 'disk_size' ],
            calculate => q| return int( $disk_num * $disk_size ); |,
        },
    ],
    has_optional => [
        comments        => { is => 'Text' },
        created         => { is => 'Text' },
        last_modified   => { is => 'Text' },
    ],
    schema_name => 'Disk',
    data_source => 'Sdm::DataSource::Disk',
};

1;
