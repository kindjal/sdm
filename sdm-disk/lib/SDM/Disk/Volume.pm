
package SDM::Disk::Volume;

use strict;
use warnings;

use SDM;
use Date::Manip;
use Smart::Comments -ENV;

my $classdef = {
    table_name => 'disk_volume',
    id_by => [
        id            => { is => 'Number' },
    ],
    has => [
        mount_path    => { is => 'Text', len => 255 },
        total_kb      => { is => 'Integer', default_value => 0 },
        used_kb       => { is => 'Integer', default_value => 0 },
    ],
    has_many_optional => [
        # Mount is optional because "Mount" is a bridge entry that may not exist yet.
        mount         => { is => 'SDM::Disk::Mount', reverse_as => 'volume' },
        filer         => { is => 'SDM::Disk::Filer', via => 'mount', to => 'filer' },
        # physical_path is analogous to hrStorageDescr in SNMP speak.
        physical_path => { via => 'mount', to => 'physical_path' },
        filername     => { via => 'filer', to => 'name' },
        hostname      => { via => 'filer', to => 'hostname' },
        arrayname     => {
            calculate => q/ my %h; foreach my $f ($self->filer) { map { $h{$_} = 1 } $f->arrayname }; return keys %h; /
        },
        gpfs_disk_perf  => { is => 'SDM::Disk::GpfsDiskPerf', reverse_as => 'volume' },
    ],
    has_optional => [
        gpfs_fs_perf    => { is => 'SDM::Disk::GpfsFsPerf', id_by => 'id' },
        group           => { is => 'SDM::Disk::Group', id_by => 'disk_group' },
        capacity        => { is => 'Number', is_calculated => 1 },
        created         => { is => 'DATE' },
        last_modified   => { is => 'DATE' },
    ],
    schema_name => 'Disk',
    data_source => 'SDM::DataSource::Disk',
};

# Only oracle needs this
my $ds = SDM::DataSource::Disk->get();
my $driver = $ds->driver;
$classdef->{id_sequence_generator_name} = 'disk_volume_id' if ($driver eq "Oracle");
class SDM::Disk::Volume $classdef;

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
    ### Volume->is_current: $vol_maxage
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

    ### Volume->is_current date0: $date0
    ### Volume->is_current date1: $date1
    ### Volume->is_current delta: $delta
    ### Volume->is_current vol_maxage: $vol_maxage

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
        $self->warning_message("Volume '" . $self->mount_path . "' has no Filers, it has been orphaned.");
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

=head2 get_or_create
Get an existing volume and create it if it doesn't exist.
=cut
sub get_or_create {
    my $self = shift;
    my (%param) = @_ if (scalar @_);
    ### Volume->get_or_create: %param
    my $volume = SDM::Disk::Volume->get( mount_path => $param{mount_path}, filername => $param{filername}, physical_path => $param{physical_path} );
    unless ($volume) {
        $volume = $self->create( %param );
    }
    return $volume;
}

=head2 create
Create a volume, error if it already exists.
=cut
sub create {
    my $self = shift;
    my (%param) = @_ if (scalar @_);

    ### Volume->create: %param
    # A fully defined Volume has, in order:
    #   - Filer->name
    #   - Export->filername + Export->physical_path
    #   - Volume->mount_path
    #   - Mount->volume_id + Mount->export_id
    #   - Group->disk_group if present
    unless ($param{filername}) {
        $self->error_message("filer name not specified in Volume->create()");
        return;
    }
    unless ($param{physical_path}) {
        $self->error_message("physical path not specified in Volume->create()");
        return;
    }
    unless ($param{mount_path}) {
        $self->error_message("mount path not specified in Volume->create()");
        return;
    }
    unless ($param{total_kb}) {
        $param{total_kb} = 0;
    }
    unless ($param{used_kb}) {
        $param{used_kb} = 0;
    }

    my $volume = SDM::Disk::Volume->get( mount_path => $param{mount_path}, filername => $param{filername}, physical_path => $param{physical_path} );
    if ($volume) {
        ### volume: $volume
        # This exact volume + mount exists
        $self->error_message("Volume already exists");
        return;
    }
    ### Volume->create volume->get: $volume

    # Note: Is it ok to auto-create Filers?  I say no for now.
    # The exact volume doesn't exist, so make sure we have the Filer
    my $filer = SDM::Disk::Filer->get( name => $param{filername} );
    unless ($filer) {
        $self->error_message("Failed to identify filer: " . $param{filername});
        return;
    }
    ### Volume->create filer->get: $filer

    # Note: Is it ok to auto-create Exports?  I say yes for now, export and mount should be "under the hood"
    # Now make sure the Filer has the Export
    my $export = SDM::Disk::Export->get_or_create( filername => $param{filername}, physical_path => $param{physical_path} );
    unless ($export) {
        $self->error_message("Failed to get_or_create export: '" . $param{filername} ." " . $param{physical_path} );
        return;
    }
    ### Volume->create export->get_or_create: $export

    # Note: Is it ok to auto-create Groups?  I say no for now, they shouldn't change often
    # and they represent real people, which we should be careful to not mess with.
    # If a group is specified, make sure we have that too
    my $group_name;
    if ($param{disk_group}) {
        $group_name = uc($param{disk_group});
        my $group = SDM::Disk::Group->get( name => $group_name );
        ### Volume->create Group->get: $group
        unless ($group) {
            $self->error_message("Failed to identify group: " . $group_name );
            return;
        }
        $param{disk_group} = $group_name;
    }

    # Now that we're sure that a Filer and Export exist, and that we don't already
    # have this exact Volume, we can add the Volume and/or Mount.
    $volume = SDM::Disk::Volume->get( mount_path => $param{mount_path} );
    unless ($volume) {
        # No volume at all at this mount, add the volume then the mount.
        $param{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
        $volume = $self->SUPER::create( mount_path => $param{mount_path}, used_kb => $param{used_kb}, total_kb => $param{total_kb}, disk_group => $group_name, created => $param{created} );
        unless ($volume) {
            $self->error_message("Failed to create volume");
            return;
        }
    }
    ### Volume->create volume->SUPER::create: $volume

    # Note: Is it ok to auto-create mounts?  I say yes for now, exports and mounts should be "under the hood".
    # Now that we have a Volume, ensure there's a mount (bridge table)
    # Mount is a bridge table between Volume and Filer.
    my $mount  = SDM::Disk::Mount->get_or_create( volume_id => $volume->id, export_id => $export->id );
    unless ($mount) {
        $self->error_message("Failed to get_or_create mount for volume");
        return;
    }
    ### Volume->create mount->get_or_create: $mount

    ### Volume->create returns volume: $volume
    return $volume;
}

=head2 delete
Delete a Volume and its Mounts, or delete the described Mounts.
=cut
sub delete {
    my $self = shift;
    my (%param) = @_;
    ### Volume->delete mount: $self
    ###  param: %param
    # Remove the Export entries, then the Mount entries, then the Volume.
    # If we gave arguments, we're specifying a filername.
    if (defined $param{filername}) {
        foreach my $m (SDM::Disk::Mount->get( filername => $param{filername} )) {
            ### Volume->delete mount: $m
            $m->delete() or die "Failed to delete mount for volume: " . $self->id;
        }
        my @mounts = $self->mount;
        unless (scalar @mounts) {
            # If we have no mounts left, remove the volume
            ### Volume->delete: $self
            return $self->SUPER::delete();
        }
    } else {
        # Otherwise remove all mounts and this Volume
        foreach my $m ($self->mount) {
            ### Volume->delete mount: $m
            $m->delete() or die "Failed to delete mount for volume: " . $self->id;
        }
        ### Volume->delete: $self
        return $self->SUPER::delete();
    }
}

1;
