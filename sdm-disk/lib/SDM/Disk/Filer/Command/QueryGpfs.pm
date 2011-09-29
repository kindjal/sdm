
package SDM::GPFS::DiskUsage;

use strict;
use warnings;
use feature 'switch';

use SDM;
use Net::SSH;
use Data::Dumper;

=head2 SDM::GPFS::DiskUsage
Class that gathers volume data from GPFS filer.
=cut
class SDM::GPFS::DiskUsage {
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

=head2 sub _ssh_cmd
General function for getting content from an ssh command.
=cut
sub _ssh_cmd {
    my $self = shift;
    my $cmd = shift;
    $self->logger->debug(__PACKAGE__ . " sshopen3: $cmd");
    Net::SSH::sshopen3('root@' . $self->hostname, *WRITER, *READER, *ERROR, "$cmd") or die "error: $cmd: $!";
    close(WRITER);
    my $error = do { local $/; <ERROR> };
    close(ERROR);
    my $content = do { local $/; <READER> };
    close(READER);
    given ($error) {
        when (defined $error and $error =~ /Permission denied/) {
            chomp $error;
            $self->logger->error(__PACKAGE__ . " " . $self->hostname . ": " . $error);
            $self->logger->error(__PACKAGE__ . " please set up ssh keys");
            exit 1;
        }
        when (defined $error and $error ne '') {
            chomp $error;
            $self->logger->error(__PACKAGE__ . " " . $self->hostname . ": " . $error);
            exit 1;
        }
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
        $volumes->{$vol}->{'mount_path'} = $self->mount_point . "/" . $vol;
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

        my @keys = ('name','type','kb_size','kb_quota','kb_limit','kb_in_doubt','kb_grace','files','file_quota','file_limit','file_in_doubt','file_grace','file_entryType','parent_volume_name');
        my @values = split(/\s+/,$line,13);
        my %params;
        @params{@keys} = @values;
        $params{parent_volume_name} = $parentVolume;

        $volumeref->{$parentVolume}->{'filesets'} = [] unless ($volumeref->{$parentVolume}->{'filesets'});
        push @{ $volumeref->{$parentVolume}->{'filesets'} }, \%params;
    }
}

=head2 sub acquire_volume_data
Run a series of commands via SSH on a GPFS filer and return a hash containing volume data.
=cut
sub acquire_volume_data {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " acquire_volume_data");

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

    return $volumes;
}

package SDM::Disk::Filer::Command::QueryGpfs;

use strict;
use warnings;

use SDM;

# Usage function
use Pod::Find qw(pod_where);
use Pod::Usage;

# Autoflush
local $| = 1;

class SDM::Disk::Filer::Command::QueryGpfs {
    is => 'SDM::Command::Base',
    has_optional => [
        filername => {
            # If I use is => Filer here, UR errors out immediately if the filer doesn't exist.
            # If I use is => Text, then I can use get_or_create to add on the fly, or query them all.
            #is => 'SDM::Disk::Filer',
            is => 'Text',
            doc => 'Query the named filer',
        },
        hostname => {
            is => 'Text',
            doc => 'Query the named host to discover and query the filer given by --filername'
        },
        force => {
            is => 'Boolean',
            default => 0,
            doc => 'Query all filers regardless of status',
        },
        allow_mount => {
            is => 'Boolean',
            default => 0,
            doc => 'Allow mounting of filesystems to discover disk groups',
        },
        mount_point => {
            is => 'Text',
            default => '/gscmnt',
            doc => 'Specify the mount_point used by autofs to access volumes, this is used with --discover_volumes',
        },
        translate_path => {
            is => 'Boolean',
            default => 0,
            doc => 'Map physical_path /vol/homeXYZ to volume name XYZ, this is an old convention',
        },
        timeout => {
            is => 'Number',
            default => 15,
            doc => 'Not yet implemented',
        },
        host_maxage => {
            is => 'Number',
            default => 86400,
            doc => 'max seconds since last check',
        },
        vol_maxage => {
            is => 'Number',
            default => 15,
            doc => 'max days until volume is considered purgable',
        },
        rrdpath => {
            is => 'Text',
            default => $ENV{SDM_DISK_RRDPATH} ||= "/var/cache/sdm/rrd",
            doc => 'Path to rrd file storage (not yet implemented)',
        },
        purge => {
            is => 'Boolean',
            default => 0,
            doc => 'Purge aged volume entries (not yet implemented)',
        },
        cleanonly => {
            is => 'Boolean',
            default => 0,
            doc => 'Remove volumes from the DB that the Filer no longer exports',
        },
        discover_groups => {
            is => 'Boolean',
            default => 0,
            doc => 'Discover disk groups from touch files on volumes and create them on the fly',
        },
        discover_volumes => {
            is => 'Boolean',
            default => 0,
            doc => 'Create volumes based on what we discover, otherwise only update volumes already defined',
        },
    ],
    doc => 'Queries volume usage of GPFS filer',
};

sub help_brief {
    return 'Updates volume usage information from GPFS filer';
}

sub help_synopsis {
    return <<EOS
Updates volume usage information from GPFS filer
EOS
}

sub help_detail {
    return <<EOS
Updates volume usage information from GPFS filer
EOS
}

=head2 update_volumes
Update data for all Volumes associated with this Filer.
=cut
sub _update_volumes {
    my $self = shift;
    my $volumedata = shift;
    # volumedata is a hash that looks like this:
    # volumedata: {
    #     'aggr0' => {
    #                       'disk_group' => undef,
    #                       'total_kb' => '11603570688',
    #                       'mount_path' => '/gscmnt/aggr0',
    #                       'name' => 'aggr0',
    #                       'used_kb' => 93415936,
    #                       'physical_path' => '/vol/aggr0'
    #                       'filesets' => [ ... ],
    #                       '...LUN...' => [ ... ],
    #                     }
    #   }
    my $filername = shift;

    unless ($filername) {
        $self->logger->error(__PACKAGE__ . " update_volumes(): no filer given");
        return;
    }
    unless ($volumedata) {
        $self->logger->warn(__PACKAGE__ . " update_volumes(): filer " . $filername . " returned empty volumedata");
        return;
    }

    $self->logger->warn(__PACKAGE__ . " update_volumes($filername)");

    # First find and remove volumes in the DB that are not detected on this filer
    # For this filer, find any stored volumes that aren't present in the volumedata.
    # Note that we skip this step if we specified a single physical_path to update.
    # FIXME: Make this include filesets too
    #my @volumes = ( SDM::Disk::Volume->get( filername => $filername ) );
    # FIXME: Don't warn if no volumes are found yet...
    #foreach my $volume ( @volumes ) {
    #    foreach my $path ($volume->physical_path) {
    #        next unless($path);
    #        $path =~ s/\//\\\//g;
    #        if ( ! grep /$path/, keys %$volumedata ) {
    #            $self->logger->warn(__PACKAGE__ . " volume is no longer exported by filer '$filername': " . $volume->id);
    #            # FIXME: do we want to auto-remove like this?
    #            #$volume->delete;
    #        }
    #    }
    #}
    #return 1 if ($self->cleanonly);

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
                $self->logger->debug(__PACKAGE__ . " created disk group: $group_name");
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
        #my $volume = SDM::Disk::Volume->get_or_create( filername => $filername, physical_path => $physical_path, name => $name );
        #my $volume = SDM::Disk::Volume->get_or_create( filername => $filername, name => $name );
        my $volume = SDM::Disk::Volume->get( filername => $filername, name => $name );
        unless ($volume) {
            $volume = SDM::Disk::Volume->create( filername => $filername, physical_path => $physical_path, name => $name );
            $self->logger->error(__PACKAGE__ . " create volume: $filername, $name");
            unless ($volume) {
                $self->logger->error(__PACKAGE__ . " failed to get_or_create volume: $filername, $physical_path, $name");
                next;
            }
        }
        $self->logger->debug(__PACKAGE__ . " found volume: $name: $filername, $physical_path");
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

            $fileset->{parent_volume_name} = $name;
            $fileset->{filername} = $filername;
            # Do this if Fileset can inherit Volume
            #$fileset->{physical_path} = $volumedata->{$name}->{physical_path} . "/" . $fileset->{name};
            #$fileset->{total_kb} = $fileset->{kb_limit};
            #$fileset->{used_kb} = $fileset->{kb_size};
            # Otherwise... move disk group to Volume below.
            my $disk_group = delete $fileset->{disk_group};

            my $fs = SDM::Disk::Fileset->get( filername => $filername, name => $fileset->{name} );
            unless ($fs) {
                $self->logger->error(__PACKAGE__ . " create fileset: $filername, " . $fileset->{name});
                $fs = SDM::Disk::Fileset->create( %$fileset );
                unless ($fs) {
                    $self->logger->error(__PACKAGE__ . " failed to get_or_create fileset: " . $fileset->{name});
                    next;
                }
            }
            $self->logger->debug(__PACKAGE__ . " found fileset: " . $fileset->{name});
            foreach my $attr (keys %$fileset) {
                next unless (defined $fileset->{$attr});
                my $p = $fs->__meta__->property($attr);
                next unless ($p);
                # Primary keys are immutable, don't try to update them
                $fs->$attr($fileset->{$attr})
                    if (! $p->is_id and $p->is_mutable);
                $fs->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
            }

            # Do this if Fileset cannot inherit Volume
            # Now create a Volume to represent the Fileset, since we can't do DB
            # level inheritance with multi-column primary keys (UR limitation).
            # If we could, we wouldn't have to do this, we could make Fileset
            # is SDM::Disk::Volume.
            my $physical_path = $volumedata->{$name}->{physical_path} . "/" . $fileset->{name};
            my $volume = SDM::Disk::Volume->get( filername => $filername, name => $fileset->{name}, physical_path => $physical_path );
            unless ($volume) {
                $volume = SDM::Disk::Volume->create( filername => $filername, name => $fileset->{name}, physical_path => $physical_path );
                unless ($volume) {

                    $self->logger->error(__PACKAGE__ . " failed to create volume for fileset: " . $fileset->{name} . ": $filername");
                    return;
                }
            }
            $volume->total_kb( $fileset->{kb_limit} );
            $volume->used_kb( $fileset->{kb_size} );
            #$volume->disk_group( $fileset->{disk_group} );
            $volume->disk_group( $disk_group );
            $self->logger->debug(__PACKAGE__ . " updated volume for fileset: " . $fileset->{name} . ": $filername, ");
        }

    }
    return 1;
}

=head2 validate_volumes
Iterate over all Volumes associated with this Filer, check is_current() and warn on all stale volumes.
NB. This isn't used or exposed yet, not sure if this is the right place to do this.
=cut
sub _validate_volumes {
    my $self = shift;
    $self->logger->error(__PACKAGE__ . " max age has not been specified\n")
        if (! defined $self->vol_maxage);
    $self->logger->error(__PACKAGE__ . " max age makes no sense: $self->vol_maxage\n")
        if ($self->vol_maxage < 0 or $self->vol_maxage !~ /\d+/);

    foreach my $volume (SDM::Disk::Volume->get( filername => $self->name )) {
        $volume->validate($self->vol_maxage);
    }
}

=head2 purge_volumes
Iterate over all Volumes associated with this Filer, check is_current() and purge all stale volumes.
NB. This isn't used or exposed yet, not sure if this is the right place to do this.
=cut
sub _purge_volumes {
    my $self = shift;
    $self->logger->error(__PACKAGE__ . " max age has not been specified\n")
        if (! defined $self->vol_maxage);
    $self->logger->error(__PACKAGE__ . " max age makes no sense: $self->vol_maxage\n")
        if ($self->vol_maxage < 0 or $self->vol_maxage !~ /\d+/);

    foreach my $volume (SDM::Disk::Volume->get( filername => $self->name )) {
        $volume->purge($self->vol_maxage);
    }
}

=head2 query_gpfs
Query the master host of a filer and update volume data.
=cut
sub _query_gpfs {
    my $self = shift;
    my (%params) = @_;
    my $filername = $params{filername};
    my $hostname = $params{hostname};

    unless ($hostname) {
        $self->logger->error(__PACKAGE__ . " filer has no known master host, define one or use --hostname");
        return;
    }

    # Query the master node hostname and update Filer data.
    eval {
        my @params = ( loglevel => $self->loglevel, hostname => $hostname );
        push @params, ( allow_mount => $self->allow_mount ) if ($self->discover_groups);
        push @params, ( translate_path => $self->translate_path );
        push @params, ( discover_volumes => $self->discover_volumes );
        push @params, ( mount_point => $self->mount_point );

        my $gpfs = SDM::GPFS::DiskUsage->create( @params );
        unless ($gpfs) {
            $self->logger->error(__PACKAGE__ . " unable to query filer host '$hostname'");
            return;
        }

        # Query disk usage numbers
        my $table = $gpfs->acquire_volume_data();
        unless ($table) {
            $self->logger->error(__PACKAGE__ . " filer host $hostname returned no data");
            return;
        }

        # Volume data must be updated before GPFS data is updated below.
        $self->_update_volumes( $table, $filername );
        $gpfs->delete();
    };
    if ($@) {
        # log here, but not high priority, it's common
        $self->logger->warn(__PACKAGE__ . " error with query: $@");
    }
    return 1;
}

=head2 execute
Execute QueryGpfs() queries on a named Filer and stores disk usage information.
=cut
sub execute {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " execute");

    # What filer to query and via what host?
    my @filers;
    if ($self->hostname and ! defined $self->filername) {
        $self->logger->error(__PACKAGE__ . " you also need to specify --filername with --hostname");
        return;
    }

    if ($self->filername) {
        # See if filer is present and has master host defined...
        my $filer = SDM::Disk::Filer->get_or_create( name => $self->filername, type => 'gpfs' );
        unless ($filer) {
            $self->logger->error(__PACKAGE__ . " failed to get or create '" . $self->filername . "'");
            return;
        }
        push @filers, $filer;
        if (defined $self->hostname) {
            my $host = SDM::Disk::Host->get_or_create( hostname => $self->hostname );
            unless ($host) {
                $self->logger->error(__PACKAGE__ . " failed to get or create host '" . $self->hostname . "'");
                return;
            }
            $host->assign( $filer->name );
            $host->master( 1 );
        }
    }

    # If not given on the CLI, ask the DB about filers we know about.
    unless (@filers) {
        if ($self->force) {
            # If "force", get all Filers and query them even if status is 0.
            @filers = SDM::Disk::Filer->get( type => 'gpfs' );
        } else {
            # Query all filers that have status => 1...
            # This is what we use for a cron job.
            @filers = SDM::Disk::Filer->get( type => 'gpfs', status => 1 );
        }
    }

    unless (@filers) {
        $self->logger->warn(__PACKAGE__ . " no filers to be scanned. Add filers if there are none, or use --hostname to query a GPFS master.");
    }

    # Otherwise, query existing filers for update
    foreach my $filer (@filers) {
        my $hostname;
        foreach my $host ($filer->host) {
            $hostname = $host->hostname if ($host->master);
        }
        my $filername = $filer->name;
        unless ($hostname) {
            $self->logger->error(__PACKAGE__ . " filer '$filername' has no master host associated with it.");
            next;
        }
        if ( $self->_query_gpfs(filername => $filername, hostname => $hostname ) ) {
            $filer->status(1);
            $filer->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
        }
    }

    UR::Context->commit();

    # Now update disk group RRD files.
    my $rrd = SDM::Utility::DiskGroupRRD->create( loglevel => $self->loglevel );
    $rrd->run();

    return 1;
}

1;
