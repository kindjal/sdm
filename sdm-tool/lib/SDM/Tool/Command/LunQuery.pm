
package SDM::Tool::Command::LunQuery;

use strict;
use warnings;

use SDM;
use Net::SSH;

class SDM::Tool::Command::LunQuery {
    is => "SDM::Command::Base",
    has => [
        hostname => { is => 'Text', doc => 'hostname of gpfs master node' },
        threshold => { is => 'Number', doc => 'threshold of slowness', default_value => 0.01 }
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
    my $mmdsh;
    my $mmfsadm;
    my $mmlsnode;
    my $multipath;

    my $cmd = "which mmdsh mmfsadm mmlsnode multipath";
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
        $mmdsh = $_ if (/\/mmdsh/);
        $mmfsadm = $_ if (/\/mmfsadm/);
        $mmlsnode = $_ if (/\/mmlsnode/);
        $multipath = $_ if (/\/multipath/);
    }
    close(READER);
    close(ERROR);

    $self->_exit("mmdsh not in PATH") unless ($mmdsh);
    $self->_exit("mmfsadm not in PATH") unless ($mmfsadm);
    $self->_exit("mmlsnode not in PATH") unless ($mmlsnode);
    $self->_exit("multipath not in PATH") unless ($multipath);

    chomp $mmdsh;
    chomp $mmfsadm;
    chomp $mmlsnode;
    chomp $multipath;

    $cmd = "$mmlsnode";
    $self->logger->debug(__PACKAGE__ . " sshopen3: $cmd");
    Net::SSH::sshopen3('root@' . $self->hostname, *WRITER, *READER, *ERROR, "$cmd") or $self->_exit("error: mmlsnode: $!");
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
    $hosts =~ s/\s+/,/g;
    $self->logger->debug(__PACKAGE__ . " cluster members: $hosts");

    my $dms;
    $cmd = "$mmdsh -L $hosts $mmfsadm dump waiters";
    $self->logger->debug(__PACKAGE__ . " sshopen3: $cmd");
    Net::SSH::sshopen3('root@' . $self->hostname, *WRITER, *READER, *ERROR, "$cmd") or $self->_exit("error running mmdsh/mmfsadm: $!");
    while (<READER>) {
        next unless (/^.* (\d+\.\d+) seconds.* (dm-.*)$/);
        my $sec = $1;
        next unless ($sec > $self->threshold);
        $dms->{$2} = $sec;
    }
    close(READER);
    close(WRITER);
    close(ERROR);

    my $luns;
    $cmd = "$multipath -l";
    $self->logger->debug(__PACKAGE__ . " sshopen3: $cmd");
    Net::SSH::sshopen3('root@' . $self->hostname, *WRITER, *READER, *ERROR, "$cmd") or $self->_exit("error running multipath: $!");
    while (<READER>) {
        next unless (/^(\w+)\s+\S+\s+(\S+)/);
        $luns->{$2} = $1;
    }
    close(READER);
    close(WRITER);
    close(ERROR);

    foreach my $dm (sort { $dms->{$a} cmp $dms->{$b} } keys %$dms) {
        print "$dm," . $luns->{$dm} . "," . $dms->{$dm} . "\n";
    }

    return 1;
}

1;

