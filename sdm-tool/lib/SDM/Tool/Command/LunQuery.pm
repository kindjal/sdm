
package SDM::Gpfs::Command::LunQuery;

use strict;
use warnings;

use SDM;
use Net::SSH;

class SDM::Gpfs::Command::LunQuery {
    is => "SDM::Command::Base",
    has => [
        hostname => { is => 'Text', doc => 'hostname of gpfs master node' }
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
    my $results = {};
    my $mmdsh;
    my $mmfsadm;
    my $mmlsnsd;
    my $hosts;
    my @hosts;
    Net::SSH::sshopen3('root@' . $self->hostname, *WRITER, *READER, *ERROR, "which mmdsh mmfsadm mmlsnsd && mmlsnode") or $self->_exit("error running mmlsnode: $!");
    while (<ERROR>) {
        if (/Permission denied/) {
            $self->logger->error("Set up ssh keys to allow access to " . $self->hostname);
            exit 1;
        }
    }
    while (<READER>) {
        $mmdsh = $_ if (/\/mmdsh/);
        $mmfsadm = $_ if (/\/mmfsadm/);
        $mmlsnsd = $_ if (/\/mmlsnsd/);
        $hosts = $_ if (/$self->hostname/);
    }
    close(READER);
    close(WRITER);

    $self->_exit("mmdsh not in PATH") unless ($mmdsh);
    $self->_exit("mmfsadm not in PATH") unless ($mmfsadm);
    $self->_exit("mmlsnsd not in PATH") unless ($mmlsnsd);
    $self->_exit("error discovering cluster members") unless ($hosts);

    @hosts = split(/\s+/);
    shift @hosts;
    $hosts = join(",",@hosts);

    Net::SSH::sshopen2('root@' . $self->hostname, *READER, *WRITER, "$mmdsh -L $hosts $mmfsadm dump waiters 2>/dev/null") or $self->_exit("error running mmdsh/mmfsadm: $!");
    DSH:
    while (<READER>) {
        next unless (/^.* (\d+\.\d+) seconds.* (dm-.*)$/);
        my $sec = $1;
        my $dm  = $2;
        next unless ($sec > 0.01);
        my $lun;

        opendir(my $dh, "/dev/mpath") or $self->_exit("error in opendir: $!");
        LUN:
        foreach my $entry (readdir($dh)) {
            next unless ($entry);
            my $target = readlink("/dev/mpath/$entry");
            if (defined $target and $target =~ /$dm/) {
                $lun = $entry;
                last LUN;
            }
        }
        closedir $dh;
        next DSH unless ($lun);
        my $nsd;
        Net::SSH::sshopen2('root@' . $self->hostname, *READER2, *WRITER2, "$mmlsnsd -d $lun 2>/dev/null") or $self->_exit("error running mmlsnsd: $!");
        while (<READER2>) {
            next if (/^[\s-]*$/);
            next if (/^ File/);
            $nsd = shift @{ [ split() ] };
        }
        close(READER2);
        close(WRITER2);
        next unless ($nsd);
        unless ($results->{$nsd}) {
            #print STDERR "lun:nsd $lun:$nsd\r";
            $results->{$nsd} = 1;
        }
    }
    close(READER);
    close(WRITER);
    my @nsds = sort keys %$results;
    print "LUNs reporting as waiters:\n";
    print join("\n", @nsds);
    print "\n";
    return 1;
}

1;

