
package System::Disk::GpfsFsPerf;

use strict;
use warnings;

use System;

class System::Disk::GpfsFsPerf {
    table_name => 'disk_gpfs_fs_perf',
    id_by => [
        id => { is => 'Number' },
    ],
    has => [
        volume_id                    => { is => 'Number' },
        volume                       => { is => 'System::Disk::Volume', id_by => 'volume_id' },
        gpfsFileSystemPerfName       => { is => 'Text', column_name => 'gpfsfilesystemperfname' },
        gpfsFileSystemBytesReadL     => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystembytesreadl' },
        gpfsFileSystemBytesReadH     => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystembytesreadh' },
        gpfsFileSystemBytesCacheL    => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystembytescachel' },
        gpfsFileSystemBytesCacheH    => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystembytescacheh' },
        gpfsFileSystemBytesWrittenL  => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystembyteswrittenl' },
        gpfsFileSystemBytesWrittenH  => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystembyteswrittenh' },
        gpfsFileSystemReads          => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystemreads' },
        gpfsFileSystemCaches         => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystemcaches' },
        gpfsFileSystemWrites         => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystemwrites' },
        gpfsFileSystemOpenCalls      => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystemopencalls' },
        gpfsFileSystemCloseCalls     => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystemclosecalls' },
        gpfsFileSystemReadCalls      => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystemreadcalls' },
        gpfsFileSystemWriteCalls     => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystemwritecalls' },
        gpfsFileSystemReaddirCalls   => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystemreaddircalls' },
        gpfsFileSystemInodesWritten  => { is => 'Number', default_value => 0, column_name => 'gpfsfilesysteminodeswritten' },
        gpfsFileSystemInodesRead     => { is => 'Number', default_value => 0, column_name => 'gpfsfilesysteminodesread' },
        gpfsFileSystemInodesDeleted  => { is => 'Number', default_value => 0, column_name => 'gpfsfilesysteminodesdeleted' },
        gpfsFileSystemInodesCreated  => { is => 'Number', default_value => 0, column_name => 'gpfsfilesysteminodescreated' },
        gpfsFileSystemStatCacheHit   => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystemstatcachehit' },
        gpfsFileSystemStatCacheMiss  => { is => 'Number', default_value => 0, column_name => 'gpfsfilesystemstatcachemiss' },
    ],
    has_optional => [
        created                      => { is => 'Date' },
        last_modified                => { is => 'Date' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

=head2 create
Create method for gpfsFsPef entry sets created attribute.
=cut
sub create {
    my $self = shift;
    my (%params) = @_;
    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    my $physical_path = $params{gpfsFileSystemPerfName};
    unless ($physical_path) {
        $self->error_message("parameters missing required attribute: gpfsFileSystemPerfName");
        return;
    }
    my $volume = System::Disk::Volume->get( physical_path => $physical_path );
    unless ($volume) {
        $self->error_message("can't find a volume with physical_path '$physical_path'" );
        return;
    }
    $params{id} = $volume->id;
    return $self->SUPER::create( %params );
}

1;
