
package System::Disk::Array::Command::Assign;

use System;
use Smart::Comments -ENV;

class System::Disk::Array::Command::Assign {
    is => 'System::Command::Base',
    has => [
        array => { is => 'System::Disk::Array', shell_args_position => 1 },
        host  => { is => 'System::Disk::Host',  shell_args_position => 2 },
    ],
    doc => 'Assign an Array to a Host',
};

sub execute {
    my $self = shift;

    my $res = System::Disk::HostArrayBridge->create( host => $self->host, array => $self->array );
    unless ($res) {
        $self->error_message("Failed to assign Host '" . $self->host . "' to Array '" . $self->array);
        return;
    }
    return $res;
}

1;
