
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
        gpfsDiskPerfName             => { is => 'Text', default_value => '', column_name => 'gpfsdiskperfname' },
        gpfsDiskPerfFSName           => { is => 'Text', default_value => '', column_name => 'gpfsdiskperffsname' },
        gpfsDiskPerfStgPoolName      => { is => 'Text', default_value => '', column_name => 'gpfsdiskperfstgpoolname'  },
        gpfsDiskReadTimeL            => { is => 'Number', default_value => 0, column_name => 'gpfsdiskreadtimel' },
        gpfsDiskReadTimeH            => { is => 'Number', default_value => 0, column_name => 'gpfsdiskreadtimeh' },
        gpfsDiskWriteTimeL           => { is => 'Number', default_value => 0, column_name => 'gpfsdiskwritetimel' },
        gpfsDiskWriteTimeH           => { is => 'Number', default_value => 0, column_name => 'gpfsdiskwritetimeh' },
        gpfsDiskLongestReadTimeL     => { is => 'Number', default_value => 0, column_name => 'gpfsdisklongestreadtimel' },
        gpfsDiskLongestReadTimeH     => { is => 'Number', default_value => 0, column_name => 'gpfsdisklongestreadtimeh' },
        gpfsDiskLongestWriteTimeL    => { is => 'Number', default_value => 0, column_name => 'gpfsdisklongestwritetimel' },
        gpfsDiskLongestWriteTimeH    => { is => 'Number', default_value => 0, column_name => 'gpfsdisklongestwritetimeh' },
        gpfsDiskShortestReadTimeL    => { is => 'Number', default_value => 0, column_name => 'gpfsdiskshortestreadtimel' },
        gpfsDiskShortestReadTimeH    => { is => 'Number', default_value => 0, column_name => 'gpfsdiskshortestreadtimeh' },
        gpfsDiskShortestWriteTimeL   => { is => 'Number', default_value => 0, column_name => 'gpfsdiskshortestwritetimel' },
        gpfsDiskShortestWriteTimeH   => { is => 'Number', default_value => 0, column_name => 'gpfsdiskshortestwritetimeh' },
        gpfsDiskReadBytesL           => { is => 'Number', default_value => 0, column_name => 'gpfsdiskreadbytesl' },
        gpfsDiskReadBytesH           => { is => 'Number', default_value => 0, column_name => 'gpfsdiskreadbytesh' },
        gpfsDiskWriteBytesL          => { is => 'Number', default_value => 0, column_name => 'gpfsdiskwritebytesl' },
        gpfsDiskWriteBytesH          => { is => 'Number', default_value => 0, column_name => 'gpfsdiskwritebytesh' },
        gpfsDiskReadOps              => { is => 'Number', default_value => 0, column_name => 'gpfsdiskreadops' },
        gpfsDiskWriteOps             => { is => 'Number', default_value => 0, column_name => 'gpfsdiskwriteops' },
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
