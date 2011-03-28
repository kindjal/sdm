
package System::Disk::Host::Command::Detach;

use System;
use Smart::Comments -ENV;

class System::Disk::Host::Command::Detach {
    is => 'System::Command::Base',
    has => [
        host  => { is => 'System::Disk::Host', shell_args_position => 1 },
        filer => { is => 'System::Disk::Filer',  shell_args_position => 2 },
    ],
    doc => 'disassociate a host from a filer',
};

sub execute {
    my $self = shift;

    foreach my $result ( System::Disk::FilerHostBridge->get( host => $self->host, filer => $self->filer ) ) {
        $self->warning_message("Disassociate Host '" . $self->host->hostname . "' from Filer '" . $self->filer->name);
        $result->delete() or die "Failed to assign Host '" . $self->host->hostname . "' from Filer '" . $self->filer->name;
    }
    return 1;
}

1;
