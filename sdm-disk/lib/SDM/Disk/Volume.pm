
package SDM::Disk::Volume;

use strict;
use warnings;

use SDM;
use Date::Manip;

=head2 SDM::Disk::Volume
A Volume may be commonly referred to by its nfs mount_path:

  /gscmnt/gc2111 -> nfshost:/vol/gc2111

  name: gc2111
  mount_point: /gscmnt
  mount_path: /gscmnt/gc2111
  filername: nfshost
  physical_path: /vol/gc2111

This scheme is born from conventions at The Genome Institute.
We must also support schemes:

  /gscmnt/400 -> nfshost:/vol/400

  name: 400
  mount_point: /gscmnt
  mount_path: /gscmnt/400
  filername: nfshost
  physical_path: /vol/400

And:

  /gscmnt/200 -> nfshost:/vol/home200

  name: 200
  mount_point: /gscmnt
  mount_path: /gscmnt/200
  filername: nfshost
  physical_path: /vol/home200

=cut
class SDM::Disk::Volume {
    table_name => 'disk_volume',
    id_generator => '-uuid',
    id_by => [
        id => { is => 'Text' },
    ],
    has => [
        name            => { is => 'Text', len => 255 },
        filername       => { is => 'Text', len => 255 },
        physical_path   => { is => 'Text', len => 255 },
        # More than one filer named fname might have /vol/home
        # but there can be only one way to nfs mount /gscmnt/home.
        # There should not be more than one mount_path for fname+physical_path,
        # this is enforce by the DB schema UNIQUE constraint.
        mount_point     => { is => 'Text', default_value => '/gscmnt' },
        mount_path      => {
            is => 'Text',
            is_calculated => 1,
            calculate_from => [ 'name','mount_point' ],
            calculate => q| return $mount_point . "/" . $name |,
        },
        filer           => { is => 'SDM::Disk::Filer', id_by => 'filername' },
        hostname        => { is => 'Text', via => 'filer', to => 'hostname' },
        arrayname       => { is => 'Text', via => 'filer', to => 'arrayname' },
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
        $self->warning_message("Aging volume: " . $self->mount_path . " " . join(',',$self->filername));
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
        $self->warning_message("Purging aging volume: " . $self->mount_path . " " . join(',',$self->filername));
        $self->delete();
    }
}

sub name {
    # Override the name accessor to prevent modifying an existing object into another existing object
    # Prevent changing filername1:name1 into an already existing filername1:name2
    my $self = shift;
    my $name = shift;
    my $filername = $self->__filername;
    if ($name) {
        if ( SDM::Disk::Volume->get( name => $name, filername => $filername ) ) {
            $self->error_message("an object already exists with name $name on filer $filername");
            return;
        }
        return $self->__name( $name );
    }
    return $self->__name();
}

sub filername {
    # Override the name accessor to prevent modifying an existing object into another existing object
    # Prevent changing filername1:name1 into an already existing filername2:name1
    my $self = shift;
    my $filername = shift;
    my $name = $self->__name;
    if ($filername) {
        if ( SDM::Disk::Volume->get( name => $name, filername => $filername ) ) {
            $self->error_message("an object already exists with name $name on filer $filername");
            return;
        }
        return $self->__filername( $filername );
    }
    return $self->__filername();
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
    if (@missing) {
        $self->error_message("missing required attributes in create(): " . join(" ",@missing));
        return;
    }

    # Note: Is it ok to auto-create Filers?  I say no for now.
    my $filer = SDM::Disk::Filer->get( name => $param{filername} );
    unless ($filer) {
        $self->error_message("failed to identify filer: " . $param{filername});
        return;
    }

    # Note: Is it ok to auto-create Groups?  I say no for now, they shouldn't change often
    # and they represent real people, which we should be careful to not mess with.
    # If a group is specified, make sure we have that too
    my $group_name;
    if ($param{disk_group}) {
        $group_name = uc($param{disk_group});
        my $group = SDM::Disk::Group->get( name => $group_name );
        unless ($group) {
            $self->error_message("failed to identify group: " . $group_name );
            return;
        }
        $param{disk_group} = $group_name;
    }

    if ($param{name} and $param{filername}) {
        my @obj = SDM::Disk::Volume->get( name => $param{name}, filername => $param{filername} );
        if (@obj) {
            $self->error_message("an object already exists with name $param{name} and filername $param{filername}");
            return;
        }
    }

    $param{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    return $self->SUPER::create( %param );
}

sub delete {
    my $self = shift;
    my @filesets = SDM::Disk::Fileset->get( parent_volume_name => $self->name );
    if (@filesets) {
        $self->error_message("cowardly refusing to delete a volume that contains filesets!  delete the filesets first!");
        return;
    }
    return $self->SUPER::delete();
}

1;
