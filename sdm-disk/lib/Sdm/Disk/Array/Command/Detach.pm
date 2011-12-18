
package Sdm::Disk::Array::Command::Detach;

use Sdm;
use Smart::Comments -ENV;

class Sdm::Disk::Array::Command::Detach {
    is => 'Sdm::Command::Base',
    has => [
        array => { is => 'Sdm::Disk::Array', shell_args_position => 1 },
        host  => { is => 'Sdm::Disk::Host',  shell_args_position => 2 },
    ],
    doc => 'disassocaite an array from a host',
};

sub execute {
    my $self = shift;

    foreach my $result ( Sdm::Disk::HostArrayBridge->get( host => $self->host, array => $self->array ) ) {
        $self->warning_message("Disassociate Host '" . $self->host->hostname . "' from Array '" . $self->array->name . "'");
        $result->delete() or die "Failed to detach Host '" . $self->host->hostname . "' from Array '" . $self->array->name . "'";
    }
    return 1;
}

1;
