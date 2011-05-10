
package System::Disk::GpfsFs;

use strict;
use warnings;

use System;

class System::Disk::GpfsFs {
    table_name => 'disk_gpfs_fs',
    id_by => [
        id => { is => 'Number' },
    ],
    has => [
        volume_id                    => { is => 'Number' },
        gpfsFileSystemPerfName       => { is => 'Text' },
        gpfsFileSystemBytesReadL     => { is => 'Number', default_value => 0 },
        gpfsFileSystemBytesReadH     => { is => 'Number', default_value => 0 },
        gpfsFileSystemBytesCacheL    => { is => 'Number', default_value => 0 },
        gpfsFileSystemBytesCacheH    => { is => 'Number', default_value => 0 },
        gpfsFileSystemBytesWrittenL  => { is => 'Number', default_value => 0 },
        gpfsFileSystemBytesWrittenH  => { is => 'Number', default_value => 0 },
        gpfsFileSystemReads          => { is => 'Number', default_value => 0 },
        gpfsFileSystemCaches         => { is => 'Number', default_value => 0 },
        gpfsFileSystemWrites         => { is => 'Number', default_value => 0 },
        gpfsFileSystemOpenCalls      => { is => 'Number', default_value => 0 },
        gpfsFileSystemCloseCalls     => { is => 'Number', default_value => 0 },
        gpfsFileSystemReadCalls      => { is => 'Number', default_value => 0 },
        gpfsFileSystemWriteCalls     => { is => 'Number', default_value => 0 },
        gpfsFileSystemReaddirCalls   => { is => 'Number', default_value => 0 },
        gpfsFileSystemInodesWritten  => { is => 'Number', default_value => 0 },
        gpfsFileSystemInodesRead     => { is => 'Number', default_value => 0 },
        gpfsFileSystemInodesDeleted  => { is => 'Number', default_value => 0 },
        gpfsFileSystemInodesCreated  => { is => 'Number', default_value => 0 },
        gpfsFileSystemStatCacheHit   => { is => 'Number', default_value => 0 },
        gpfsFileSystemStatCacheMiss  => { is => 'Number', default_value => 0 },
    ],
    has_optional => [
        created                      => { is => 'Date' },
        last_modified                => { is => 'Date' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

=head2 create
Create method for gpfsFs entry sets created attribute.
=cut
sub create {
    my $self = shift;
    my (%params) = @_;
    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    my $mount_path = $params{gpfsFileSystemPerfName};
    unless ($mount_path) {
        $self->error_message("parameters missing required attribute: gpfsFileSystemPerfName");
        return;
    }
    my $volume = System::Disk::Volume->get( mount_path => $mount_path );
    unless ($volume) {
        $self->error_message("can't find a volume with mount_path '$mount_path'" );
        return;
    }
    $params{id} = $volume->id;
    return $self->SUPER::create( %params );
}

1;
