
package SDM::Disk::Array::Command::Detach;

use SDM;
use Smart::Comments -ENV;

class SDM::Disk::Array::Command::Detach {
    is => 'SDM::Command::Base',
    has => [
        array => { is => 'SDM::Disk::Array', shell_args_position => 1 },
        host  => { is => 'SDM::Disk::Host',  shell_args_position => 2 },
    ],
    doc => 'disassocaite an array from a host',
};

sub execute {
    my $self = shift;

    foreach my $result ( SDM::Disk::HostArrayBridge->get( host => $self->host, array => $self->array ) ) {
        $self->warning_message("Disassociate Host '" . $self->host->hostname . "' from Array '" . $self->array->name . "'");
        $result->delete() or die "Failed to detach Host '" . $self->host->hostname . "' from Array '" . $self->array->name . "'";
    }
    return 1;
}

1;
