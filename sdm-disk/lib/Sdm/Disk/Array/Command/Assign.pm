
package Sdm::Disk::Array::Command::Assign;

use Sdm;
use Smart::Comments -ENV;

class Sdm::Disk::Array::Command::Assign {
    is => 'Sdm::Command::Base',
    has => [
        array => { is => 'Sdm::Disk::Array', shell_args_position => 1 },
        host  => { is => 'Sdm::Disk::Host',  shell_args_position => 2 },
    ],
    doc => 'assign an array to a host',
};

sub execute {
    my $self = shift;

    my $res = Sdm::Disk::HostArrayBridge->create( host => $self->host, array => $self->array );
    unless ($res) {
        $self->error_message("Failed to assign Host '" . $self->host->hostname . "' to Array '" . $self->array->name . "'");
        return;
    }
    return $res;
}

1;
