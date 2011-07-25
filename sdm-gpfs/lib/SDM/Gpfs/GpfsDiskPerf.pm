
package SDM::Gpfs::GpfsDiskPerf;

use strict;
use warnings;

use SDM;

class SDM::Gpfs::GpfsDiskPerf {
    id_by => [
        # FIXME: id_by should be gpfsClusterName, but UR breaks with an id_by that isn't "id"
        id => { is => 'Number' },
    ],
    has => [
        gpfsDiskPerfName            => { is => 'Text' },
        gpfsDiskPerfFSName          => { is => 'Text' },
        gpfsDiskPerfStgPoolName     => { is => 'Text' },
        gpfsDiskReadTimeL           => { is => 'Number' },
        gpfsDiskReadTimeH           => { is => 'Number' },
        gpfsDiskWriteTimeL          => { is => 'Number' },
        gpfsDiskWriteTimeH          => { is => 'Number' },
        gpfsDiskLongestReadTimeL    => { is => 'Number' },
        gpfsDiskLongestReadTimeH    => { is => 'Number' },
        gpfsDiskLongestWriteTimeL   => { is => 'Number' },
        gpfsDiskLongestWriteTimeH   => { is => 'Number' },
        gpfsDiskShortestReadTimeL   => { is => 'Number' },
        gpfsDiskShortestReadTimeH   => { is => 'Number' },
        gpfsDiskShortestWriteTimeL  => { is => 'Number' },
        gpfsDiskShortestWriteTimeH  => { is => 'Number' },
        gpfsDiskReadBytesL          => { is => 'Number' },
        gpfsDiskReadBytesH          => { is => 'Number' },
        gpfsDiskWriteBytesL         => { is => 'Number' },
        gpfsDiskWriteBytesH         => { is => 'Number' },
        gpfsDiskReadOps             => { is => 'Number' },
        gpfsDiskWriteOps            => { is => 'Number' },
        mount_path                  => { is => 'Text' },
        filername                   => { is => 'Text' },
        filer                       => { is => 'SDM::Disk::Filer',  id_by => 'filername' },
        volume_name                 => { is => 'Text' },
        volume                      => { is => 'SDM::Disk::Volume', id_by => 'volume_name' },
    ],
    has_constant => [
        snmp_table                  => { is => 'Text', value => 'gpfsDiskPerfTable' }
    ],
    data_source => UR::DataSource::Default->create(),
};

sub __load__ {
    my ($class, $bx, $headers) = @_;
    # Load from either a filername arg or a volume_name in the bx.

    # Make a header row from class properties.
    my @properties = $class->__meta__->properties;
    my @header = map { $_->property_name } sort @properties;
    push @header, 'id';
    # Return an empty list if error.
    my @rows;

    my $mount_path;
    my $filername;
    my $volume;

    my $volume_name = $bx->value_for( "volume_name" );

    # We either need a volume id or a filername
    if ($volume_name) {
        $volume  = SDM::Disk::Volume->get( id => $volume_name );
        $mount_path = $volume->mount_path;
        $filername = $volume->filername;
    } else {
        my (%params) = $bx->_params_list;
        $filername = $params{filername};
        $mount_path = $params{mount_path};
    }

    unless ($filername) {
        $class->error_message(__PACKAGE__ . " no filer to query.  nothing to do.");
        return \@header, \@rows;
    }

    my $filer = SDM::Disk::Filer->get( name => $filername );
    unless ($filer) {
        $class->error_message(__PACKAGE__ . " no filer named $filername found");
        return \@header, \@rows;
    }

    # Query master node of cluster for SNMP table.
    my $master;
    foreach my $host ( $filer->host ) {
        $master = $host->hostname if ($host->master);
    }
    unless ($master) {
        $class->error_message(__PACKAGE__ . " filer named $filername has no 'snmp master' set");
        return \@header, \@rows;
    }
    my $snmp = SDM::Utility::SNMP->create( hostname => $master );
    my $snmp_table = $bx->subject_class_name->__meta__->property_meta_for_name('snmp_table')->default_value;
    my $table = $snmp->read_snmp_into_table( $snmp_table );

    # Build a result from this hash of one hash.
    my $id;
    while (my ($key,$result) = each %$table ) {
        if (defined $mount_path) {
            if ($mount_path !~ /\/$result->{gpfsDiskPerfFSName}$/) {
                #warn "skip $key " . $result->{gpfsDiskPerfFSName};
                next;
            }
        }
        $result->{id} = $id++;
        # These are calculated properties.
        $result->{filername} = $filername;
        $result->{filer} = $filer;
        $result->{volume} = $volume;
        $result->{volume_name} = $volume_name;
        $result->{mount_path} = $mount_path;
        $result->{snmp_table} = $snmp_table;
        # These are from the SNMP table.
        my @row = map {
            my $v = $result->{$_};
            $v = int($v) if ( defined $v and defined $bx->subject_class_name->__meta__->property_meta_for_name($_)->data_type and $bx->subject_class_name->__meta__->property_meta_for_name($_)->data_type eq 'Number' );
            $v;
        } @header;
        push @rows, [@row];
    }

    return \@header, \@rows;
}

1;
