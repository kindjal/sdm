
package SDM::Disk::Filer::Command::Query::GpfsDiskUsage;

use strict;
use warnings;
use feature 'switch';

use SDM;
use Net::SSH;
use Data::Dumper;

class SDM::Disk::Filer::Command::Query::GpfsDiskUsage {
    is => 'SDM::Command::Base',
    has => [
        filer => {
            is => 'SDM::Disk::Filer',
            doc => 'The Filer to query'
        },
        hostname => {
            is => 'Text',
            via => 'filer',
            to => 'master',
            doc => 'Hostname of the cluster master',
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
        },
        discover_groups => {
            is => 'Boolean',
            default_value => 0,
            doc => 'Discover groups on the target filer'
        }
    ],
    has_optional => [
        mount_path_rule => {
            is => 'Text',
            default_value => '^(/vol/aggr0|/vol):/gscmnt',
            doc => 'Colon separated rule to translate physical_path to mount_path.  Used with discover_volumes. eg: /vol:/gscmnt'
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

=head2 sub _ssh_cmd
General function for getting content from an ssh command.
=cut
sub _ssh_cmd {
    my $self = shift;
    my $cmd = shift;
    $self->logger->debug(__PACKAGE__ . " sshopen3: $cmd");
    my $content;
    eval {
        $content = Net::SSH::ssh_cmd('root@' . $self->hostname, "$cmd");
    };
    if ($@) {
        $self->error_message("error with ssh: $@");
        return;
    }
    return $content;
}

=head2 parse_mmlscluster
Add all hosts and make one GPFS master
=cut
sub _parse_mmlscluster {
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

    sub _splithost {
        my $host = shift;
        if ($host =~ /\./) {
            my $toss;
            ($host,$toss) = split(/\./,$host,2);
        }
        return $host;
    }

    $master = _splithost($master);
    @hosts = map { _splithost($_) } @hosts;

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

=head2 _parse_mmlsnsd
Obtain a hash reference containing Volumes from GPFS's mmlsnsd command
=cut
sub _parse_mmlsnsd {
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
        my $mount_path = $volumes->{$vol}->{'physical_path'};
        my ($from,$to) = split(/:/,$self->mount_path_rule);
        $mount_path =~ s/$from/$to/;
        $volumes->{$vol}->{'mount_path'} = $mount_path;
    }
    return $volumes;
}

=head2 _parse_nsd_df
Update a volume hashref with usage info from "df -P" output
=cut
sub _parse_nsd_df {
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

=head2 _parse_disk_groups
Update a volume hashref with disk group info from a "find" command.
=cut
sub _parse_disk_groups {
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
        my ($volume,$group) = @parts[-2,-1];
        $group  =~ s/^DISK_//;
        if ($volumeref->{$volume}) {
            $volumeref->{$volume}->{'disk_group'} = $group;
            next;
        }
        foreach my $key (keys %$volumeref) {
            if ($volumeref->{$key}->{'filesets'}) {
                foreach my $fileset (@{ $volumeref->{$key}->{'filesets'} }) {
                    $fileset->{'disk_group'} = $group if ($fileset->{'name'} eq $volume);
                }
            }
        }
    }
}

=head2 _parse_mmrepquota
Update a volume hashref with fileset data from GPFS's mmrepquota command.
=cut
sub _parse_mmrepquota {
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

        my @keys = ('name','type','kb_size','kb_quota','kb_limit','kb_in_doubt','kb_grace','files','file_quota','file_limit','file_in_doubt','file_grace','file_entrytype','parent_volume_name');
        my @values = split(/\s+/,$line,13);
        my %params;
        @params{@keys} = @values;
        $params{parent_volume_name} = $parentVolume;

        $volumeref->{$parentVolume}->{'filesets'} = [] unless ($volumeref->{$parentVolume}->{'filesets'});
        push @{ $volumeref->{$parentVolume}->{'filesets'} }, \%params;
    }
}

=head2 update_volumes
Update data for all Volumes associated with this Filer.
=cut
sub _update_volumes {
    my $self = shift;
    my $volumedata = shift;

    my $filer = $self->filer;
    my $filername = $filer->name;

    unless ($filer) {
        $self->logger->error(__PACKAGE__ . " update_volumes(): no filer given");
        return;
    }
    unless ($volumedata) {
        $self->logger->warn(__PACKAGE__ . " update_volumes(): filer $filername returned empty volumedata");
        return;
    }

    $self->logger->warn(__PACKAGE__ . " update_volumes($filername)");

    foreach my $name (keys %$volumedata) {

        # Ensure we have Groups before we update this attribute of a Volume or Fileset
        my @groups;
        # Filesets have groups only if they inherit Volume
        @groups = map { $_->{disk_group} if ($_->{disk_group}) } @{ $volumedata->{$name}->{filesets} } if ($volumedata->{$name}->{filesets});
        push @groups, $volumedata->{$name}->{disk_group} if ($volumedata->{$name}->{disk_group});
        @groups = grep { defined $_ } @groups;
        foreach my $group_name (@groups) {
            my $group;
            if ($self->discover_groups) {
                $group = SDM::Disk::Group->get_or_create( name => $group_name );
                $self->logger->debug(__PACKAGE__ . " get_or_create disk group: $group_name");
            } else {
                $group = SDM::Disk::Group->get( name => $group_name );
            }
            unless ($group) {
                $self->logger->error(__PACKAGE__ . " ignoring currently unknown disk group: $group_name");
                next;
            }
        }

        # Now we have groups, so add the volumes we've discovered.
        my $physical_path = $volumedata->{$name}->{physical_path};
        my $volume = SDM::Disk::Volume->get( filername => $filername, physical_path => $physical_path );
        unless ($volume) {
            unless ($self->discover_volumes) {
                $self->logger->warn(__PACKAGE__ . " ignoring new volume: $filername, $physical_path, consider --discover-volumes");
                next;
            }
            $volume = SDM::Disk::Volume->create( filername => $filername, physical_path => $physical_path );
            $self->logger->error(__PACKAGE__ . " create volume: $filername, $physical_path");
            unless ($volume) {
                $self->logger->error(__PACKAGE__ . " failed to get or create volume: $filername, $physical_path");
                next;
            }
        }
        $self->logger->debug(__PACKAGE__ . " found volume: $filername, $physical_path");
        foreach my $attr (keys %{ $volumedata->{$name} }) {
            next unless (defined $volumedata->{$name}->{$attr});
            # FIXME: Don't update disk group from filesystem, only the reverse.
            #next if ($attr eq 'disk_group');
            my $p = $volume->__meta__->property($attr);
            next unless ($p);
            # Primary keys are immutable, don't try to update them
            $volume->$attr($volumedata->{$name}->{$attr})
                if (! $p->is_id and $p->is_mutable);
            $volume->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
        }

        # Create filesets if present
        foreach my $fileset (@{ $volumedata->{$name}->{filesets} }) {

            my $parent = delete $fileset->{parent_volume_name};
            my $physical_path = $volumedata->{$name}->{physical_path} . "/$parent";
            my $id = SDM::Disk::Volume->get( physical_path => $physical_path );

            $fileset->{parent_volume_id} = $volume->id;
            $fileset->{filername} = $filername;
            $fileset->{physical_path} = $volumedata->{$name}->{physical_path} . "/" . delete $fileset->{name};
            $fileset->{total_kb} = $fileset->{kb_limit};
            $fileset->{used_kb} = $fileset->{kb_size};
            my $mount_path = $fileset->{physical_path};
            my ($from,$to) = split(/\:/,$self->mount_path_rule);
            $mount_path =~ s/$from/$to/;
            $fileset->{mount_path} = $mount_path;

            my $fs = SDM::Disk::Fileset->get( filername => $filername, physical_path => $fileset->{physical_path} );
            unless ($fs) {
                $self->logger->error(__PACKAGE__ . " create fileset: $filername, " . $fileset->{physical_path});
                $fs = SDM::Disk::Fileset->create( %$fileset );
                unless ($fs) {
                    $self->logger->error(__PACKAGE__ . " failed to get or create fileset: " . $fileset->{physical_path});
                    next;
                }
            }
            $self->logger->debug(__PACKAGE__ . " found fileset: " . $fileset->{physical_path});
            foreach my $attr (keys %$fileset) {
                next unless (defined $fileset->{$attr});
                my $p = $fs->__meta__->property($attr);
                next unless ($p);
                # Primary keys are immutable, don't try to update them
                $fs->$attr($fileset->{$attr})
                    if (! $p->is_id and $p->is_mutable);
                $fs->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
            }
            $self->logger->debug(__PACKAGE__ . " updated volume for fileset: " . $fileset->{physical_path} . ": $filername, ");
        }

    }
    $filer->status(1);
    $filer->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
    return 1;
}

=head2 sub acquire_volume_data
Run a series of commands via SSH on a GPFS filer and return a hash containing volume data.
=cut
sub acquire_volume_data {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " acquire_volume_data");

    unless ($self->hostname) {
        $self->logger->error(__PACKAGE__ . " filer '" . $self->filer->name . "' has no master host associated with it.");
        return;
    }

    # mmlscluster get cluster members
    $self->_parse_mmlscluster( $self->_ssh_cmd( "/usr/lpp/mmfs/bin/mmlscluster" ) );
    # mmlsnsd get volumes
    my $volumes = $self->_parse_mmlsnsd( $self->_ssh_cmd( "/usr/lpp/mmfs/bin/mmlsnsd" ) );
    # get usage info from df -P
    $self->_parse_nsd_df( $self->_ssh_cmd( "/bin/df -P" ), $volumes );
    # mmrepquota get filesets, where are also volumes
    $self->_parse_mmrepquota( $self->_ssh_cmd( "/usr/lpp/mmfs/bin/mmrepquota -ja" ), $volumes );
    # get disk groups via touch files for each volume
    $self->_parse_disk_groups( $self->_ssh_cmd( "/usr/bin/find /vol -mindepth 2 -maxdepth 3 -type f -name \"DISK_*\" 2>/dev/null" ), $volumes );

    $self->_update_volumes( $volumes );
}

1;
