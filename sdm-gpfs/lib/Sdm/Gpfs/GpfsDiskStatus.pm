
package Sdm::Gpfs::GpfsDiskStatus;

use strict;
use warnings;

use Sdm;

class Sdm::Gpfs::GpfsDiskStatus {
    id_by => [
        # FIXME: id_by should be gpfsDiskStatusName, but UR breaks with an id_by that isn't "id"
        id => { is => 'Number' },
    ],
    has => [
        filername                   => { is => 'Text' },
        gpfsDiskName                => { is => 'Text' },
        gpfsDiskFSName              => { is => 'Text' },
        gpfsDiskStgPoolName         => { is => 'Text' },
        gpfsDiskStatus              => { is => 'Text' },
        gpfsDiskAvailability        => { is => 'Text' },
        gpfsDiskTotalSpaceL         => { is => 'Number' },
        gpfsDiskTotalSpaceH         => { is => 'Number' },
        gpfsDiskFullBlockFreeSpaceL => { is => 'Number' },
        gpfsDiskFullBlockFreeSpaceH => { is => 'Number' },
        gpfsDiskSubBlockFreeSpaceL  => { is => 'Number' },
        gpfsDiskSubBlockFreeSpaceH  => { is => 'Number' },
    ],
    has_optional => [
        filer                       => { is => 'Sdm::Disk::Filer',  id_by => 'filername' },
        volume                      => { is => 'Sdm::Disk::Volume', id_by => 'gpfsDiskFSName' }
    ],
    has_constant => [
        snmp_table                  => { is => 'Text', value => 'gpfsDiskStatusTable' }
    ],
    data_source => UR::DataSource::Default->create(),
};

sub __load__ {
    my ($class, $bx, $headers) = @_;
    my (%params) = $bx->_params_list;
    my $filername = $params{filername};
    my $snmp_table = $bx->subject_class_name->__meta__->property_meta_for_name('snmp_table')->default_value;

    # Make a header row from class properties.
    my @properties = $class->__meta__->properties;
    my @header = map { $_->property_name } sort @properties;
    push @header, 'id';

    # Return an empty list if error.
    my @rows;
    my $filer = Sdm::Disk::Filer->get( name => $filername );
    unless ($filer) {
        $class->error_message(__PACKAGE__ . " no filer named $filername found");
        return \@header, \@rows;
    }

    # Query master node of cluster for SNMP table.
    my $master;
    foreach my $host ( $filer->host ) {
        $master = $host->hostname if ($host->master);
    }
    my $snmp = Sdm::Utility::SNMP->create( hostname => $master );
    my $table = $snmp->read_snmp_into_table( $snmp_table );

    # Build a result from this hash of one hash.
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
