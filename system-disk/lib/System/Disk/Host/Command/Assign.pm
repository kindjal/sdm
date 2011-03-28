
package System::Disk::Host::Command::Assign;

use System;
use Smart::Comments -ENV;

class System::Disk::Host::Command::Assign {
    is => 'System::Command::Base',
    has => [
        host  => { is => 'System::Disk::Host', shell_args_position => 1 },
        filer => { is => 'System::Disk::Filer',  shell_args_position => 2 },
    ],
    doc => 'assign a host to a filer',
};

sub execute {
    my $self = shift;

    my $res = System::Disk::FilerHostBridge->create( host => $self->host, filer => $self->filer );
    unless ($res) {
        $self->error_message("Failed to assign Host '" . $self->host->hostname . "' to Filer '" . $self->filer->name . "'");
        return;
    }
    return $res;
}

1;
