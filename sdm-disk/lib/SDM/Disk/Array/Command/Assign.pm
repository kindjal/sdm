
package SDM::Disk::Array::Command::Assign;

use SDM;
use Smart::Comments -ENV;

class SDM::Disk::Array::Command::Assign {
    is => 'SDM::Command::Base',
    has => [
        array => { is => 'SDM::Disk::Array', shell_args_position => 1 },
        host  => { is => 'SDM::Disk::Host',  shell_args_position => 2 },
    ],
    doc => 'assign an array to a host',
};

sub execute {
    my $self = shift;

    my $res = SDM::Disk::HostArrayBridge->create( host => $self->host, array => $self->array );
    unless ($res) {
        $self->error_message("Failed to assign Host '" . $self->host->hostname . "' to Array '" . $self->array->name . "'");
        return;
    }
    return $res;
}

1;
