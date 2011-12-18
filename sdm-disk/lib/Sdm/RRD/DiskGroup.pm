
package Sdm::RRD::DiskGroup;

use Sdm::RRD;
use Smart::Comments -ENV;

class Sdm::RRD::DiskGroup {
    id_by => [
        filename => { is => 'Text' },
    ],
    has => [
        name              => { is => 'Text' },
        type              => { is => 'Text' },
        minimal_heartbeat => { is => 'Number' },
        min               => { is => 'Number' },
        max               => { is => 'Number' },
        last_ds           => { is => 'Number' },
        value             => { is => 'Number' },
        unknown_sec       => { is => 'Number' },
    ],
    data_source => UR::DataSource::Default->create(),
};

sub __load__ {
    my ($self, $bx, $headers) = @_;
    my @header = ( 'name', 'type', 'minimal_heartbeat', 'min', 'max', 'last_ds', 'value', 'unknown_sec' );
    my @rows = ();
    push @rows,  [ 'filename', 'id', 'name', 'type', 'minimal_heartbeat', 'min', 'max', 'last_ds', 'value', 'unknown_sec' ];
    unshift @header, 'filename';
    unshift @header, 'id';

    my $fn = $bx->value_for('filename');
    ### fn: $fn
    my $rrd = RRDTool::OO->new( file => $fn );
    print $rrd->info();

    return \@header, sub { shift @rows; }

}

1;
