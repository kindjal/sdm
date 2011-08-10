
package SDM::Gpfs::Command::CreateFilesystem;

use SDM;
use IPC::Cmd qw/can_run/;

class SDM::Gpfs::Command::CreateFilesystem {
    is => 'SDM::Command::Base',
    has => [
        name => {
            is => 'Text',
            doc => 'specify filesystem name'
        },
        number => {
            is => 'Number',
            doc => 'specify number of NSDs to assign to name'
        },
        array => {
            is => 'Text',
            default_value => '',
            doc => 'specify an array name from which to select free disks'
        },
    ]
};

sub execute {
    my $mmlsnds = can_run("mmlsnsd");
    unless ($mmlsnsd) {
        $self->logger->error(__PACKAGE__ . " cannot find mmlsnsd in PATH");
            return;
    }
    my $mmcrfs = can_run("mmcrfs");
    unless ($mmcrfs) {
        $self->logger->error(__PACKAGE__ . " cannot find mmcrfs in PATH");
            return;
    }
    my $array = $self->array;
    my $number = $self->number;
    my $arg = qx( $mmlsnsd -F | sed -e '1,/^-*\$/d' | awk "/$array/{print \$3}" | head -n $number | tr '\n' ';' );
    unless ($arg) {
        $self->logger->error(__PACKAGE__ . " error identifying free NSDs");
            return;
    }

    my $cmd = join(" ",$mmcrfs,"/vol/" . $self->name,$self->name,$arg,"-A yes");
    if ($self->_ask_user_question( "Ok to run: $cmd", 0) eq 'y') {
        $self->logger->warn(__PACKAGE__ . " execute");
        #qx($cmd);
    } else {
        $self->logger->warn(__PACKAGE__ . " aborted");
    }
    return;
}

1;
