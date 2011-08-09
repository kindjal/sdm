
package SDM::Gpfs::Command::GetMembers;

use strict;
use warnings;

use SDM;
use Net::SSH;

class SDM::Gpfs::Command::GetMembers {
    is => "SDM::Command::Base",
    doc => 'ssh to a gpfs cluster master node discover cluster members',
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
    my $mmlsnode;

    my $cmd = "which mmlsnode";
    $self->logger->debug(__PACKAGE__ . " sshopen3: $cmd");
    Net::SSH::sshopen3('root@' . $self->hostname, *WRITER, *READER, *ERROR, "PATH=\"/usr/lpp/mmfs/bin:\$PATH\" $cmd") or $self->_exit("error: which: $!");
    close(WRITER);
    while (<ERROR>) {
        print;
        if (/Permission denied/) {
            $self->logger->error("Set up ssh keys to allow access to " . $self->hostname);
            exit 1;
        }
    }
    while (<READER>) {
        $mmlsnode = $_ if (/\/mmlsnode/);
    }
    close(READER);
    close(ERROR);

    $self->_exit("mmlsnode not in PATH") unless ($mmlsnode);

    chomp $mmlsnode;

    # Get cluster membership
    $cmd = "$mmlsnode";
    $self->logger->debug(__PACKAGE__ . " sshopen3: $cmd");
    Net::SSH::sshopen3('root@' . $self->hostname, *WRITER, *READER, *ERROR, "$cmd") or $self->_exit("error: $cmd: $!");
    while (<ERROR>) {
        print;
        if (/Permission denied/) {
            $self->logger->error("Set up ssh keys to allow access to " . $self->hostname);
            exit 1;
        }
    }
    my $hosts;
    my @hosts;
    while (<READER>) {
        my $hostname = $self->hostname;
        $hosts = $1 if (/^\s+\S+\s+(.*$hostname.*)$/);
    }
    close(READER);
    close(WRITER);
    close(ERROR);
    $self->_exit("error discovering cluster members") unless ($hosts);
    chomp $hosts;
    $hosts =~ s/\s+$//;
    @hosts = split(/\s+/,$hosts);
    $self->logger->debug(__PACKAGE__ . " cluster members: " . join(',',@hosts));
    return @hosts;
}

1;

