
package Sdm::Disk::Host::Command::Detach;

use Sdm;
use Smart::Comments -ENV;

class Sdm::Disk::Host::Command::Detach {
    is => 'Sdm::Command::Base',
    has => [
        host  => { is => 'Sdm::Disk::Host', shell_args_position => 1 },
        filer => { is => 'Sdm::Disk::Filer',  shell_args_position => 2 },
    ],
    doc => 'disassociate a host from a filer',
};

sub execute {
    my $self = shift;

    foreach my $result ( Sdm::Disk::FilerHostBridge->get( host => $self->host, filer => $self->filer ) ) {
        $self->warning_message("Disassociate Host '" . $self->host->hostname . "' from Filer '" . $self->filer->name . "'");
        $result->delete() or die "Failed to assign Host '" . $self->host->hostname . "' from Filer '" . $self->filer->name . "'";
    }
    return 1;
}

1;
