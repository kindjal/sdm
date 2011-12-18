
package Sdm::Disk::Host::Command::Assign;

use Sdm;
use Smart::Comments -ENV;

class Sdm::Disk::Host::Command::Assign {
    is => 'Sdm::Command::Base',
    has => [
        host  => { is => 'Sdm::Disk::Host', shell_args_position => 1 },
        filer => { is => 'Sdm::Disk::Filer',  shell_args_position => 2 },
    ],
    doc => 'assign a host to a filer',
};

sub execute {
    my $self = shift;

    my $res = Sdm::Disk::FilerHostBridge->create( host => $self->host, filer => $self->filer );
    unless ($res) {
        $self->error_message("Failed to assign Host '" . $self->host->hostname . "' to Filer '" . $self->filer->name . "'");
        return;
    }
    return $res;
}

1;
