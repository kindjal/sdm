
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
        mountpoint   => {
            is_calculated => 1,
            calculate_from => 'filename',
            calculate => q| $filename =~ m/\S+\s\((\S+)\)/; return $1; |,
        },
        server => {
            is_calculated => 1,
            calculate_from => 'filename',
            calculate => q| $filename =~ m/\S+\s\((\S+):(\S+)\)/; return $1; |,
        },
        filername => {
            is_calculated => 1,
            calculate_from => 'server',
            calculate => q| my $h = shift @{ [ gethostbyname($server) ] }; my @g = split(/\./,$h,2); return $g[0]; |,
        },
        physical_path => {
            is_calculated => 1,
            calculate_from => 'filename',
            calculate => q| $filename =~ m/\S+\s\((\S+):(\S+)\)/; return $2; |,
        },
        export => {
            is => 'SDM::Disk::Export',
            is_calculated => 1,
            calculate_from => [ 'filername', 'physical_path' ],
            calculate => q| return SDM::Disk::Export->get( filername => $filername, physical_path => $physical_path ); |,
        },
        volume => {
            is => 'SDM::Disk::Volume',
            is_calculated => 1,
            calculate_from => [ 'filername', 'physical_path' ],
            calculate => q| return SDM::Disk::Volume->get( filername => $filername, physical_path => $physical_path ); |,
        },
        hostname     => { is => 'Text' },
        pid          => { is => 'Integer' },
        process      => { is => 'SDM::Service::Lsof::Process', id_by => ['hostname','pid'] }
    ],
};

1;
