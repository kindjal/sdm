
package Sdm::Service::Lsof::File;

use strict;
use warnings;

use Sdm;

class Sdm::Service::Lsof::File {
    is => 'Sdm::Service::Lsof',
    data_source => 'Sdm::DataSource::Service',
    schema_name => 'Service',
    table_name => 'service_lsof_file',
    id_by => [
        filename     => { is => 'Text' },
        hostname     => { is => 'Text' },
        pid          => { is => 'Integer' },
    ],
    has => [
        process      => { is => 'Sdm::Service::Lsof::Process', id_by => ['hostname','pid'] },
        mount_point   => {
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
            # This assumes an NFS mount filename format: filename (server:mount_point)
            calculate => q| $filename =~ m/\S+\s\((\S+):(\S+)\)/; return $2; |,
        },
        volume => {
            is => 'Sdm::Disk::Volume',
            is_calculated => 1,
            calculate_from => [ 'filername', 'physical_path' ],
            calculate => q| return Sdm::Disk::Volume->get( filername => $filername, physical_path => $physical_path ); |,
        },
    ],
};

1;
