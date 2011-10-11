
package SDM::Disk::Volume;

use strict;
use warnings;

use SDM;
use Date::Manip;

class SDM::Disk::Volume {
    table_name => 'disk_volume',
    id_generator => '-uuid',
    id_by => [
        id => { is => 'Text' },
    ],
    has => [
        physical_path   => { is => 'Text' },
        total_kb        => { is => 'Number', default_value => 0 },
        #total_kb        => { is => 'SDM::Value::KBytes', default_value => 0 },
        used_kb         => { is => 'Number', default_value => 0 },
        #used_kb         => { is => 'SDM::Value::KBytes', default_value => 0 },
        capacity        => {
            is => 'Number',
            calculate => q( my $u = $self->used_kb; my $t = $self->total_kb; my $c = 0; if ($t) { $c = $u/$t * 100 }; return $c; )
        },
    ],
    has_optional => [
        mount_path      => { is => 'Text' },
        comments        => { is => 'Text' },
        created         => { is => 'DATE' },
        last_modified   => { is => 'DATE' },
        mount_options   => { is => 'Text', default_value => '-intr,tcp,rsize=32768,wsize=32768' },
        group           => { is => 'SDM::Disk::Group', id_by => 'disk_group' },
        #gpfs_disk_perf  => { is => 'SDM::Gpfs::GpfsDiskPerf', reverse_as => 'volume' },
        gpfs_fsperf_id  => {
            is => 'Number',
            calculate_from => 'mount_path',
            calculate   => q/
                use File::Basename;
                my $name = File::Basename::basename $mount_path;
                my @f = SDM::Gpfs::GpfsFileSystemPerf->get( gpfsFileSystemPerfName => $name );
                return map { $_->id } @f;
            /,
        },
        gpfs_filesystem_perf => { is => 'SDM::Gpfs::GpfsFileSystemPerf', id_by => 'gpfs_fsperf_id' },
        fileset_cap => {
            is => 'Number',
            calculate_from => 'total_kb',
            calculate => q|
                my $kb;
                foreach my $fs ( $self->fileset ) {
                    $kb += $fs->kb_limit;
                }
                return sprintf "%0.2d%%", $kb/$total_kb*100;
            |,
        },
        fileset_total => {
            is => 'Number',
            calculate => q|
                my $kb;
                foreach my $fs ($self->fileset) {
                    $kb += $fs->kb_limit;
                }
                return $kb;
            |,
        },
    ],
    has_many_optional => [
        filermappings    => { is => 'SDM::Disk::VolumeFilerBridge', reverse_as => 'volume' },
        filer   => { is => 'SDM::Disk::Filer', via => 'filermappings', to => 'filer' },
        filername       => { is => 'Text', via => 'filer', to => 'name' },
        hostname        => { is => 'Text', via => 'filer', to => 'hostname' },
        arrayname       => { is => 'Text', via => 'filer', to => 'arrayname' },
        fileset => {
            is => 'SDM::Disk::Fileset',
            reverse_as => 'volume'
        }
    ],
    schema_name => 'Disk',
    data_source => 'SDM::DataSource::Disk',
};

=head2 _new
This is a private method that is used so that the unit tests can call SUPER::create()
=cut
sub _new {
    # This _new() method is only for testing.
    my $class = shift;
    my $self = $class->SUPER::create( @_ );
    return $self;
}


=head2 assign
Assign a volume to a filer.
=cut
sub assign {
    my $self = shift;
    my $filername = shift;
    unless ($filername) {
        $self->error_message("specify a filer name to assign this volume to");
        return;
    }
    my $filer = SDM::Disk::Filer->get( name => $filername );
    unless ($filer) {
        $self->error_message("the filer named '$filername' is unknown");
        return;
    }
    my $res = SDM::Disk::VolumeFilerBridge->get_or_create( volume => $self, filer => $filer );
    return $res;
}

=head2 is_current
Check the given Volume's last_modified time and compare it to time().  If the difference is
greater than vol_maxage, the volume is considered "stale" and a candiate for purging.
=cut
sub is_current {
    my $self = shift;
    my $vol_maxage = shift;
    # Default max age is 15 days.
    $vol_maxage = 1296000 unless (defined $vol_maxage and $vol_maxage > 0);
    return 0 if (! defined $self->last_modified);
    return 0 if ($self->last_modified eq "0000-00-00 00:00:00");

    my $date0 = $self->last_modified;
    $date0 =~ s/[- :]//g;
    $date0 = ParseDate($date0);
    return 0 if (! defined $date0);

    my $err;
    my $date1 = ParseDate( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time() ) );
    my $calc = DateCalc($date0,$date1,\$err);

    die "Error in DateCalc: $date0, $date1, $err\n" if ($err);
    die "Error in DateCalc: $date0, $date1, $err\n" if (! defined $calc);

    my $delta = int(Delta_Format($calc,0,'%st'));

    return 0 if (! defined $delta);
    return 1
        if $delta > $vol_maxage;
    return 0;
}

=head2 validate
Apply is_current() reporting the result to STDOUT.
=cut
sub validate {
    my $self = shift;
    my $vol_maxage = shift;
    unless ($self->is_current($vol_maxage)) {
        $self->warning_message("Aging volume: " . $self->id);
    }
}

=head2 is_orphan
Determine if the volume has a filer.  If not, it's an orphan and should be removed.
=cut
sub is_orphan {
    my $self = shift;
    my $filer = $self->filer;
    unless ($filer) {
        return 1;
    }
    return 0;
}

=head2 purge
Apply is_current() and delete all those that fail that test.
=cut
sub purge {
    my $self = shift;
    my $vol_maxage = shift;
    unless ($self->is_current($vol_maxage)) {
        $self->warning_message("Purging aging volume: " . $self->id);
        $self->delete();
    }
}

=head2 create
Create a volume, error if it already exists.
=cut
sub create {
    my $self = shift;
    my (%param) = @_ if (scalar @_);

    my @missing;
    foreach my $attr ( $self->__meta__->properties ) {
        next if ($attr->is_optional or $attr->via or $attr->is_calculated or $attr->is_id or $attr->id_by or defined $attr->default_value);
        push @missing, $attr->property_name unless (exists $param{$attr->property_name});
    }
    # filername isn't required at the table level because we want to allow a many-to-many relationship
    # via a bridge table.  So we want to "assign" a volume to a filer via the bridge table.  So, we
    # need a filer to assign to (see below), but it's not a Volume attribute at the table level.
    push @missing, 'filername' unless ($param{filername});
    if (@missing) {
        $self->error_message("missing required attributes in create(): " . join(" ",@missing));
        return;
    }

    # Is this a duplictae volume?  Volume-Filer is many to many
    my @volumes = SDM::Disk::Volume->get( physical_path => $param{physical_path}, filername => $param{filername} );
    if (@volumes) {
        $self->error_message("filer $param{filername} already has a volume $param{physical_path}");
        return;
    }

    # Note: Is it ok to auto-create Groups?  I say no for now, they shouldn't change often
    # and they represent real people, which we should be careful to not mess with.
    # If a group is specified, make sure we have that too
    my $group_name;
    if ($param{disk_group}) {
        $group_name = $param{disk_group};
        my $group = SDM::Disk::Group->get( name => $group_name );
        if ($group) {
            $param{disk_group} = $group_name;
        } else {
            $self->error_message("failed to identify group: " . $group_name );
        }
    }

    # A volume must be assigned to a filer.
    my $filername = delete $param{filername};
    my $filer = SDM::Disk::Filer->get( name => $filername );
    unless ($filer) {
        $self->error_message("no filer named '$filername' known");
        return;
    }

    $param{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    my $volume = $self->SUPER::create( %param );
    $volume->assign( $filername );
    return $volume;
}

sub delete {
    my $self = shift;
    foreach my $fs (SDM::Disk::Fileset->get( parent_volume_id => $self->id )) {
        $self->warning_message("Remove Fileset " . $fs->physical_path . " for Volume " . $self->physical_path);
        $fs->delete() or
            die "Failed to remove Fileset for Volume: $!";
    }

    # Remove Volume-Filer mappings
    foreach my $fm ( $self->filermappings ) {
        $self->warning_message("Remove Volume-Filer mapping " . $fm->filername . " for Volume " . $self->id);
        $fm->delete() or
            die "Failed to remove Volume-Filer map for Volume: $!";
    }

    return $self->SUPER::delete();
}

1;
