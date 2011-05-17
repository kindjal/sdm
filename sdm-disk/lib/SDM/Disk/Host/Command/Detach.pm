
package SDM::Disk::Host::Command::Detach;

use SDM;
use Smart::Comments -ENV;

class SDM::Disk::Host::Command::Detach {
    is => 'SDM::Command::Base',
    has => [
        host  => { is => 'SDM::Disk::Host', shell_args_position => 1 },
        filer => { is => 'SDM::Disk::Filer',  shell_args_position => 2 },
    ],
    doc => 'disassociate a host from a filer',
};

sub execute {
    my $self = shift;

    foreach my $result ( SDM::Disk::FilerHostBridge->get( host => $self->host, filer => $self->filer ) ) {
        $self->warning_message("Disassociate Host '" . $self->host->hostname . "' from Filer '" . $self->filer->name . "'");
        $result->delete() or die "Failed to assign Host '" . $self->host->hostname . "' from Filer '" . $self->filer->name . "'";
    }
    return 1;
}

1;
