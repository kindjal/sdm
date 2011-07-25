
package SDM::Gpfs::GpfsDiskConfig;

use strict;
use warnings;

use SDM;

class SDM::Gpfs::GpfsDiskConfig {
    id_by => [
        # FIXME: id_by should be gpfsClusterName, but UR breaks with an id_by that isn't "id"
        id => { is => 'Number' },
    ],
    has => [
        filername                   => { is => 'Text' },
        gpfsDiskConfigName          => { is => 'Text' },
        gpfsDiskConfigFSName        => { is => 'Text' },
        gpfsDiskConfigStgPoolName   => { is => 'Text' },
        gpfsDiskMetadata            => { is => 'Text' },
        gpfsDiskData                => { is => 'Text' },
    ],
    has_optional => [
        volume                      => { is => 'SDM::Disk::Volume', id_by => 'gpfsDiskConfigFSName' },
        filer                       => { is => 'SDM::Disk::Filer',  id_by => 'filername' }
    ],
    has_constant => [
        snmp_table                  => { is => 'Text', value => 'gpfsDiskConfigTable' }
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
    while (my ($key,$result) = each %$table) {
        $result->{id} = $id++;
        $result->{filername} = $filername;
        # Ensure values are in the same order as the header row.
        my @row = map { $result->{$_} } @header;
        push @rows, [@row];
    }
    return \@header, \@rows;
}

1;
