
package System::Disk::Filer::Command::GpfsMapper;

use strict;
use warnings;

use System;
use IPC::Cmd qw(can_run);
use Smart::Comments -ENV;

class System::Disk::Filer::Command::GpfsMapper {
    is => 'System::Command::Base',
    doc => 'map GPFS NSD to friendly name',
    has => [
        config => { is => 'Text', default => '/etc/gpfsmapper.conf' },
        mpconfig => { is => 'Text', default => '/etc/multipath.conf' },
    ],
    has_optional => [
        mulitpath => { is => 'Boolean', default => 0 },
        disklist => { is => 'Boolean', default => 0 },
    ],
};

sub help_brief {
    return 'GPFS operations related to mmlscluster and multipath';
}

sub help_synopsis {
    return <<EOS
GPFS operations related to mmlscluster and multipath
EOS
}

sub help_detail {
    return <<EOS
GPFS operations related to mmlscluster and multipath
EOS
}

sub read_config {
    # Read the config file specified to get the friendly name map.
    # File has format:
    #   key value
    #   ...
    my $self = shift;
    $self->{array_map} = undef;

    die("configuration file not defined\n")
        if (! defined $self->{config});
    die("configuration file not found: $self->{config}\n")
        if (! -f $self->{config});
    die("configuration file is empty: $self->{config}\n")
        if (! -s $self->{config});

    open(FH,"<$self->{config}") or
        die("open failed: $self->{config}: $!\n");

    my $error = 0;
    while (<FH>) {
        chomp;
        next if (/^($|#)/);
        my ($key,$value) = split();
        if ($key !~ /^[a-f0-9]{29}/) {
            $self->warn("invalid WWID: chars not in [a-f0-9]: $key\n");
            $error = 1;
        }
        if (length($key) != 29) {
            $self->warn("invalid WWID: not 29 chars long: $key\n");
            $error = 1;
        }
        if (! defined $value) {
            $self->warn("invalid alias: undefined: $value\n");
            $error = 1;
        }
        $self->{array_map}->{$key} = $value;
    }
    close(FH);
    die("failed to parse config: $self->{config}\n")
        if ($error);

    # Array map should be non-empty
    die("configuration file is empty: $self->{config}\n")
        if (! defined $self->{array_map} );
}

sub run_multipath {
    # Build the mapping of dm and wwid to array + lun

    my $self = shift;

    my $mp = can_run("multipath");
    die "cannot find 'multipath' in PATH" unless ($mp);

    open(MP,"$mp -l |") or
        die("cannot exec multipath: $mp: $!");
    while (<MP>) {
        if (/(^[0-9a-z]{33})\s+(dm-\d+)/
                or /^\S+\s\(([0-9a-f]{33})\)\s+(dm-\d+)/) {
            my $wwid = $1;
            my $dmid = $2;
            my $arrayid = substr($wwid,0,29);
            my $lunid = substr($wwid,-4);
            if (! exists($self->{array_map}->{$arrayid})) {
                die("No friendly name known for array: $arrayid\n");
            }
            $self->{dm_map}->{$dmid} = $self->{array_map}->{$arrayid} . $lunid;
            $self->{wwid_map}->{$wwid} = $self->{array_map}->{$arrayid} . $lunid;
        }
    }
    close(MP);

}

sub read_multipath_conf {

    my $self = shift;
    my $print = shift;

    my $mpconfig = $self->{mpconfig};
    die("cannot find 'multipath.conf' at $mpconfig\n")
        if (! -f $mpconfig);

    # read in existing multipath.conf
    my @mpfile;
    open(CONF,"<$mpconfig") or
        die("open failed: $mpconfig: $!\n");
    while (<CONF>) {
        last if (/^multipaths/);
        push @mpfile, $_;
    }
    close(CONF);
    return join('',@mpfile);
}

sub print_multipath {
    my $self = shift;

    print $self->read_multipath_conf();
    print "multipaths {\n";
    foreach my $wwid (sort keys %{ $self->{wwid_map} }) {
        print  "  multipath {\n";
        print  "    wwid $wwid\n";
        print  "    alias $self->{wwid_map}->{$wwid}\n";
        print  "  }\n";
    }
    print "}\n";
}

sub read_mmlscluster {
    my $self = shift;

    my $mm = can_run("mmlscluster");
    die("cannot find 'mmlscluster' in PATH\n") unless ($mm);
    open(MM,"$mm |") or
        die("cannot exec mmlscluster: $mm: $!");
    my @hosts;
    my $seen = 0;
    while (<MM>) {
        $seen = 1 if (/Node/);
        next unless ($seen);
        #  Node Daemon_node_name IP_address Admin_node_name Designation
        if (/^\s+\d+\s+(\S+)\s+\S+\s+\S+\s+quorum/) {
            push @hosts,$1;
        }
    }
    close(MM);

    foreach my $dmid (sort keys %{ $self->{dm_map} }) {
        print "$self->{dm_map}->{$dmid}:" . join(',',@hosts) . "::dataAndMetadata::$self->{dm_map}->{$dmid}\n";
        push @hosts, (shift @hosts);
    }
}

sub execute {
    my $self = shift;

    $self->{dm_map} = {};
    $self->{wwid_map} = {};
    $self->{array_map} = {};

    $self->read_config();
    $self->run_multipath();

    # Parse multipath output for use by mmlscluster
    if ($self->multipath) {
        $self->print_multipath();
        return 1;
    }
    if ($self->disklist) {
        $self->read_mmlscluster();
        return 1;
    }
    $self->warning_message("Please provide either --disklist or --multipath option");
    return;
}

1;

