
package System::Disk::GpfsDiskPerf;

use strict;
use warnings;

use System;

class System::Disk::GpfsDiskPerf {
    table_name => 'disk_gpfs_disk_perf',
    id_by => [
        id => { is => 'Number' },
    ],
    has => [
        volume                       => { is => 'System::Disk::Volume', id_by => 'volume_id' },
        volume_id                    => { is => 'Number' },
        gpfsDiskPerfName             => { is => 'Text', default_value => '' },
        gpfsDiskPerfFSName           => { is => 'Text', default_value => '' },
        gpfsDiskPerfStgPoolName      => { is => 'Text', default_value => '' },
        gpfsDiskReadTimeL            => { is => 'Number', default_value => 0 },
        gpfsDiskReadTimeH            => { is => 'Number', default_value => 0 },
        gpfsDiskWriteTimeL           => { is => 'Number', default_value => 0 },
        gpfsDiskWriteTimeH           => { is => 'Number', default_value => 0 },
        gpfsDiskLongestReadTimeL     => { is => 'Number', default_value => 0 },
        gpfsDiskLongestReadTimeH     => { is => 'Number', default_value => 0 },
        gpfsDiskLongestWriteTimeL    => { is => 'Number', default_value => 0 },
        gpfsDiskLongestWriteTimeH    => { is => 'Number', default_value => 0 },
        gpfsDiskShortestReadTimeL    => { is => 'Number', default_value => 0 },
        gpfsDiskShortestReadTimeH    => { is => 'Number', default_value => 0 },
        gpfsDiskShortestWriteTimeL   => { is => 'Number', default_value => 0 },
        gpfsDiskShortestWriteTimeH   => { is => 'Number', default_value => 0 },
        gpfsDiskReadBytesL           => { is => 'Number', default_value => 0 },
        gpfsDiskReadBytesH           => { is => 'Number', default_value => 0 },
        gpfsDiskWriteBytesL          => { is => 'Number', default_value => 0 },
        gpfsDiskWriteBytesH          => { is => 'Number', default_value => 0 },
        gpfsDiskReadOps              => { is => 'Number', default_value => 0 },
        gpfsDiskWriteOps             => { is => 'Number', default_value => 0 },
    ],
    has_optional => [
        created                      => { is => 'Date' },
        last_modified                => { is => 'Date' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

=head2 create
Create method for gpfsDiskPerf entry sets created attribute.
=cut
sub create {
    my $self = shift;
    my (%params) = @_;
    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    unless ($params{gpfsDiskPerfFSName}) {
        $self->error_message("parameters missing required attribute: gpfsDiskPerfFSName");
        return;
    }
    my $physical_path =  $params{gpfsDiskPerfFSName};
    my $volume = System::Disk::Volume->get( physical_path => $physical_path );
    unless ($volume) {
        $self->error_message("can't find a volume with physical_path '$physical_path'" );
        return;
    }
    $params{volume_id} = $volume->id;
    return $self->SUPER::create( %params );
}

1;
