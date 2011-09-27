
package SDM::Utility::GPFS::DiskUsage;

use strict;
use warnings;
use feature 'switch';

use SDM;
use Data::Dumper;
$Data::Dumper::Terse = 1;

class SDM::Utility::GPFS::DiskUsage {
    is => 'SDM::Command::Base',
    has => [
        hostname => {
            is => 'Text',
            default_value => undef,
            doc => 'Hostname of GPFS cluster master',
        },
        allow_mount => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Allow automounter to mount volumes to find disk groups'
        },
        discover_volumes => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Discover volumes on the target filer'
        }
    ],
    has_optional => [
        mount_point => {
            is => 'Text',
            default_value => '/gscmnt',
            doc => 'Mount point used by autofs to mount target filer.  Only for discover_volumes mode.'
        },
        translate_path => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Map physical_path /vol/homeXYZ to volume name XYZ, this is an old convention',
        }
    ],
    has_transient => [
        disk_groups => {
            default_value => {},
            is => 'HASH',
        }
    ]
};

sub ssh_cmd {
    my $self = shift;
    my $cmd = shift;
    $self->logger->debug(__PACKAGE__ . " sshopen3: $cmd");
    Net::SSH::sshopen3('root@' . $self->hostname, *WRITER, *READER, *ERROR, "$cmd") or $self->_exit("error: $cmd: $!");
    close(WRITER);
    close(ERROR);
    my $content = do { local $/; <READER> };
    close(READER);
    return $content;
}

=head2 parse_mmlscluster
Add all hosts and make one GPFS master
=cut
sub parse_mmlscluster {
    my $self = shift;
    my $content = shift;
    return unless ($content);
    $self->logger->debug(__PACKAGE__ . " parse mmlscluster");
    my @lines = split("\n",$content);
    my $master;
    my @hosts;
    foreach my $line (@lines) {
        given ($line) {
            when (/Primary server:\s+(\S+)/) {
                $master = $1;
            }
            when (/^\s+\d+\s+(\S+)/) {
                push @hosts, $1;
            }
        }
    }

    sub splithost {
        my $host = shift;
        if ($host =~ /\./) {
            my $toss;
            ($host,$toss) = split(/\./,$host,2);
        }
        return $host;
    }

    $master = splithost($master);
    @hosts = map { splithost($_) } @hosts;

    $self->logger->debug(__PACKAGE__ . " hosts: " . join(",",@hosts));
    foreach my $host (@hosts) {
        my $h = SDM::Disk::Host->get_or_create( hostname => $host );
        unless ($h) {
            $self->error_message("cannot get_or_create cluster member host $host");
            return;
        }
        if ($host eq $master) {
            $self->logger->debug(__PACKAGE__ . " master host: $host");
            $h->master(1);
        }
    }
}

sub parse_mmlsnsd {
    my $self = shift;
    my $content = shift;
    return unless ($content);
    $self->logger->debug(__PACKAGE__ . " parse mmlsnsd");
    my @lines = split("\n",$content);
    my $volumes;
    foreach my $line (@lines) {
        next if ($line =~ /^$/ or $line =~ /^-/ or $line =~ /^ File/ or $line =~ /^\s+\(free/);
        $line =~ s/^\s+//;
        my ($vol,$disk,$hosts) = split(/\s+/,$line,3);
        $volumes->{$vol} = {} unless ($volumes->{$vol});
        $volumes->{$vol}->{$disk} = [ split(/,/,$hosts) ];
        $volumes->{$vol}->{'physical_path'} = "/vol/" . $vol;
        $volumes->{$vol}->{'mount_path'} = $self->mount_point . "/" . $vol;
    }
    return $volumes;
}

sub parse_nsd_df {
    my $self = shift;
    my $content = shift;
    my $volumeref = shift;
    return unless ($content);
    $self->logger->debug(__PACKAGE__ . " parse nsd df");
    my @lines = split("\n",$content);
    foreach my $line (@lines) {
        next if ($line !~ /^\//);
        # /dev/aggr0           1092014213120 210499456768 881514756352      20% /vol/aggr0
        my ($vol,$total,$used,$avail,$cap,$mount) = split(/\s+/,$line,6);
        $vol =~ s/^\/dev\///;
        next unless ($volumeref->{$vol});
        $volumeref->{$vol}->{'total_kb'} = $total;
        $volumeref->{$vol}->{'used_kb'} = $used;
    }
}

sub parse_disk_groups {
    my $self = shift;
    my $content = shift;
    my $volumeref = shift;
    return unless ($content);
    $self->logger->debug(__PACKAGE__ . " parse disk groups");
    my @lines = split("\n",$content);
    foreach my $line (@lines) {
        # /vol/gc4020/DISK_INFO_ALIGNMENTS
        # /vol/aggr0/gc7000/DISK_INFO_ALIGNMENTS
        my @parts = split(/\//,$line);
        my ($vol,$group) = @parts[-2,-1];
        next unless ($volumeref->{$vol});
        $group  =~ s/^DISK_//;
        $volumeref->{$vol}->{'disk_group'} = $group;
    }
}

sub parse_mmrepquota {
    my $self = shift;
    my $content = shift;
    my $volumeref = shift;
    return unless ($content);
    $self->logger->debug(__PACKAGE__ . " parse mmrepquota");
    my @lines = split("\n",$content);
    my $filesets;
    my $parentVolume;
    foreach my $line (@lines) {
        $parentVolume = $1 if ($line =~ /^\*\*\*.*quotas on (.*)/);
        next if ($line =~ /^\W+/ or $line =~ /^Name/ or $line =~ /root/);
        $line =~ s/\|//g;
        $line =~ s/\s+$//g;
        next unless ($volumeref->{$parentVolume});
        $volumeref->{$parentVolume}->{'filesets'} = [] unless ($volumeref->{$parentVolume}->{'filesets'});
        push @{ $volumeref->{$parentVolume}->{'filesets'} }, [ split(/\s+/,$line,13) ];
    }
}

sub acquire_volume_data {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " acquire_volume_data");


    # mmlscluster get cluster members
    $self->parse_mmlscluster( $self->ssh_cmd( "mmlscluster" ) );

    # mmlsnsd get volumes
    my $volumes = $self->parse_mmlsnsd( $self->ssh_cmd( "mmlsnsd" ) );
    # get usage info from df -P
    $self->parse_nsd_df( $self->ssh_cmd( "df -P" ), $volumes );
    # mmrepquota get filesets, where are also volumes
    $self->parse_mmrepquota( $self->ssh_cmd( "mmrepquota" ), $volumes );
    # get disk groups via touch files for each volume
    $self->parse_disk_groups( $self->ssh_cmd( "/usr/bin/find /vol -mindepth 2 -maxdepth 3 -type f -name \"DISK_*\" 2>/dev/null" ), $volumes );

    return $volumes;
}

1;
