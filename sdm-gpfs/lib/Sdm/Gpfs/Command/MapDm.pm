
package Sdm::Gpfs::Command::MapDm;

use strict;
use warnings;

use Sdm;
use Net::SSH;

class Sdm::Gpfs::Command::MapDm {
    is => "Sdm::Command::Base",
    doc => 'ssh to a gpfs cluster and map multi-device name to volume name',
    has => [
        hostname => { is => 'Text', doc => 'hostname of gpfs master node' },
    ]
};

sub _exit {
    my $self = shift;
    my $msg = shift;
    $self->logger->error($msg);
    exit 1;
}

sub execute {
    my $self = shift;

    # Get the mapping from lun name to dm name. This is the slowest part.
    my $luns;
    my $cmd = "multipath -l";
    $self->logger->debug(__PACKAGE__ . " sshopen3: $cmd");
    Net::SSH::sshopen3('root@' . $self->hostname, *WRITER, *READER, *ERROR, "$cmd") or $self->_exit("error running $cmd: $!");
    while (<READER>) {
        next unless (/^(\w+)\s+\S+\s+(\S+)/);
        $luns->{$1} = $2;
    }
    close(READER);
    while (<ERROR>) {
        print;
        if (/Permission denied/) {
            $self->logger->error("Set up ssh keys to allow access to " . $self->hostname);
            exit 1;
        }
    }
    close(WRITER);
    close(ERROR);

    # Get the mapping from volume name to lun name.
    my $vols;
    $cmd = "mmlsnsd";
    $self->logger->debug(__PACKAGE__ . " sshopen3: $cmd");
    Net::SSH::sshopen3('root@' . $self->hostname, *WRITER, *READER, *ERROR, "PATH=/usr/lpp/mmfs/bin $cmd") or $self->_exit("error running $cmd: $!");
    while (<READER>) {
        next unless (/^\s+(\S+)\s+(\S+)/);
        $vols->{$1} = $luns->{$2};
    }
    close(READER);
    close(WRITER);
    close(ERROR);

    return $vols;
}

1;

