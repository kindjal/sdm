
package SDM::Disk::GpfsFileSystemPerf;

use strict;
use warnings;

use SDM;

class SDM::Disk::GpfsFileSystemPerf {
    id_by => [
        # FIXME: id_by should be gpfsClusterName, but UR breaks with an id_by that isn't "id"
        id => { is => 'Number' },
    ],
    has => [
        filername                    => { is => 'Text' },
        filer                        => { is => 'SDM::Disk::Filer', id_by => 'filername' },
        volume                       => { is => 'SDM::Disk::Volume', id_by => 'mount_path' },
        mount_path                   => {
            calculate_from  => 'gpfsFileSystemPerfName',
            calculate       => q( return "/gscmnt/" . shift )
        },
        gpfsFileSystemPerfName       => { is => 'Text' },
        gpfsFileSystemBytesReadL     => { is => 'Number' },
        gpfsFileSystemBytesReadH     => { is => 'Number' },
        gpfsFileSystemBytesCacheL    => { is => 'Number' },
        gpfsFileSystemBytesCacheH    => { is => 'Number' },
        gpfsFileSystemBytesWrittenL  => { is => 'Number' },
        gpfsFileSystemBytesWrittenH  => { is => 'Number' },
        gpfsFileSystemReads          => { is => 'Number' },
        gpfsFileSystemCaches         => { is => 'Number' },
        gpfsFileSystemWrites         => { is => 'Number' },
        gpfsFileSystemOpenCalls      => { is => 'Number' },
        gpfsFileSystemCloseCalls     => { is => 'Number' },
        gpfsFileSystemReadCalls      => { is => 'Number' },
        gpfsFileSystemWriteCalls     => { is => 'Number' },
        gpfsFileSystemReaddirCalls   => { is => 'Number' },
        gpfsFileSystemInodesWritten  => { is => 'Number' },
        gpfsFileSystemInodesRead     => { is => 'Number' },
        gpfsFileSystemInodesDeleted  => { is => 'Number' },
        gpfsFileSystemInodesCreated  => { is => 'Number' },
        gpfsFileSystemStatCacheHit   => { is => 'Number' },
        gpfsFileSystemStatCacheMiss  => { is => 'Number' },
    ],
    has_constant => [
        snmp_table                  => { is => 'Text', value => 'gpfsFileSystemPerfTable' }
    ],
    data_source => UR::DataSource::Default->create(),
};

sub __load__ {
    my ($class, $bx, $headers) = @_;

    # Make a header row from class properties.
    my @properties = $class->__meta__->properties;
    my @header = map { $_->property_name } sort @properties;
    push @header, 'id';
    my @rows = [];

    my (%params) = $bx->_params_list;
    my $filername = $params{filername};
    unless ($filername) {
        $class->warning_message(__PACKAGE__ . " no filername specified to query SNMP");
        return \@header, sub { shift @rows };
    }
    my $snmp_table = $bx->subject_class_name->__meta__->property_meta_for_name('snmp_table')->default_value;

    my $filer = SDM::Disk::Filer->get( name => $filername );
    unless ($filer) {
        $class->error_message(__PACKAGE__ . " no filer named $filername found");
        return \@header, sub { shift @rows };
    }

    # Query master node of cluster for SNMP table.
    my $master;
    foreach my $host ( $filer->host ) {
        $master = $host->hostname if ($host->master);
    }
    my $snmp = SDM::Utility::SNMP->create( hostname => $master );
    my $table = $snmp->read_snmp_into_table( $snmp_table );

    my $id;
    while (my ($key,$result) = each %$table ) {
        $result->{id} = $id++;
        $result->{filername} = $filername;
        # Ensure values are in the same order as the header row.
        my @row = map { $result->{$_} } @header;
        push @rows, [@row];
    }
    return \@header, \@rows;
}

1;
