
package SDM::Disk::Host::Command::Assign;

use SDM;
use Smart::Comments -ENV;

class SDM::Disk::Host::Command::Assign {
    is => 'SDM::Command::Base',
    has => [
        host  => { is => 'SDM::Disk::Host', shell_args_position => 1 },
        filer => { is => 'SDM::Disk::Filer',  shell_args_position => 2 },
    ],
    doc => 'assign a host to a filer',
};

sub execute {
    my $self = shift;

    my $res = SDM::Disk::FilerHostBridge->create( host => $self->host, filer => $self->filer );
    unless ($res) {
        $self->error_message("Failed to assign Host '" . $self->host->hostname . "' to Filer '" . $self->filer->name . "'");
        return;
    }
    return $res;
}

1;
