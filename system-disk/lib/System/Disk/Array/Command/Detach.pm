
package System::Disk::Array::Command::Detach;

use System;
use Smart::Comments -ENV;

class System::Disk::Array::Command::Detach {
    is => 'System::Command::Base',
    has => [
        array => { is => 'System::Disk::Array', shell_args_position => 1 },
        host  => { is => 'System::Disk::Host',  shell_args_position => 2 },
    ],
    doc => 'disassocaite an array from a host',
};

sub execute {
    my $self = shift;

    foreach my $result ( System::Disk::HostArrayBridge->get( host => $self->host, array => $self->array ) ) {
        $self->warning_message("Disassociate Host '" . $self->host->hostname . "' from Array '" . $self->array->name);
        $result->delete() or die "Failed to detach Host '" . $self->host->hostname . "' from Array '" . $self->array->name;
    }
    return 1;
}

1;
