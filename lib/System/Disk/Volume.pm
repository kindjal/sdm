
package System::Disk::Volume;

use strict;
use warnings;

use Date::Manip;
use System;

use Smart::Comments -ENV;

class System::Disk::Volume {
    table_name => 'DISK_VOLUME',
    id_by => [
        id            => { is => 'Number' },
    ],
    has => [
        mount_path    => { is => 'Text', len => 255 },
    ],
    has_many_optional => [
        # Mount is optional because "Mount" is a bridge entry that may not exist yet.
        mounts        => { is => 'System::Disk::Mount', reverse_as => 'volume' },
        filername     => { via => 'mounts' },
        physical_path => { via => 'mounts' },
        exports       => { is => 'System::Disk::Export', reverse_as => 'volume' },
    ],
    has_optional => [
        group         => { is => 'System::Disk::Group', id_by => 'disk_group', constraint_name => 'VOLUME_GROUP_FK' },
        total_kb      => { is => 'UnsignedInteger' },
        used_kb       => { is => 'UnsignedInteger' },
        capacity      => { is => 'Number', is_calculated => 1 },
        created       => { is => 'DATE' },
        last_modified => { is => 'DATE' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
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

=head2 validate_volumes
Iterate through all volumes and apply is_current() reporting the result to STDOUT.
=cut
sub validate_volumes {
    my $self = shift;
    foreach my $volume (System::Disk::Volume->get()) {
        unless ($volume->is_current) {
            $self->warning_message("Aging volume: " . $volume->mount_path . " " . join(',',$volume->filername));
        }
    }
}

=head2 purge
Iterate through all volumes and apply is_current() and delete all those that fail that test.
=cut
sub purge {
    my $self = shift;
    foreach my $volume (System::Disk::Volume->get()) {
        unless ($volume->is_current) {
            $self->warning_message("Purging aging volume: " . $volume->mount_path . " " . join(',',$volume->filername));
            $volume->delete();
        }
    }
}

=head2 get_or_create
Get an existing volume and create it if it doesn't exist.
=cut
sub get_or_create {
    my $self = shift;
    my (%param) = @_ if (scalar @_);
    ### Volume->get_or_create: %param
    my $volume = System::Disk::Volume->get( mount_path => $param{mount_path}, filername => $param{filername}, physical_path => $param{physical_path} );
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

    my $volume = System::Disk::Volume->get( mount_path => $param{mount_path}, filername => $param{filername}, physical_path => $param{physical_path} );
    if ($volume) {
        ### volume: $volume
        # This exact volume + mount exists
        $self->error_message("Volume already exists");
        return;
    }
    ### Volume->create volume->get: $volume

    # The exact volume doesn't exist, so make sure we have the Filer
    my $filer = System::Disk::Filer->get_or_create( name => $param{filername} );
    unless ($filer) {
        $self->error_message("Failed to add filer: " . $param{filername});
        return;
    }
    ### Volume->create filer->get_or_create: $filer

    # Now make sure the Filer has the Export
    my $export = System::Disk::Export->get_or_create( filername => $param{filername}, physical_path => $param{physical_path} );
    unless ($export) {
        $self->error_message("Failed to add export: '" . $param{filername} ." " . $param{physical_path} );
        return;
    }
    ### Volume->create export->get_or_create: $export

    # If a group is specified, make sure we have that too
    if ($param{group}) {
        my $group = System::Disk::Group->get_or_create( name => $param{group} );
        unless ($group) {
            $self->error_message("Unable to create group: " . $param{group} );
            return;
        }
    }

    # Now that we're sure that a Filer and Export exist, and that we don't already
    # have this exact Volume, we can add the Volume and/or Mount.
    $volume = System::Disk::Volume->get( mount_path => $param{mount_path} );
    unless ($volume) {
        # No volume at all at this mount, add the volume then the mount.
        $param{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
        $volume = $self->SUPER::create( mount_path => $param{mount_path}, used_kb => $param{used_kb}, total_kb => $param{total_kb}, disk_group => $param{disk_group}, created => $param{created} );
        unless ($volume) {
            $self->error_message("Unable to create volume");
            return;
        }
    }
    ### Volume->create volume->SUPER::create: $volume

    # Now that we have a Volume, ensure there's a mount (bridge table)
    # Mount is a bridge table between Volume and Filer.
    my $mount  = System::Disk::Mount->get_or_create( volume_id => $volume->id, export_id => $export->id );
    unless ($mount) {
        $self->error_message("Failed to add mount for volume");
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
    my (%param) = @_ if (scalar @_);
    my @args;
    ### Volume->delete: $self
    ###   param: %param
    # Remove the Export entries, then the Mount entries, then the Volume
    #   - Export->filername + Export->physical_path
    #   - Volume->mount_path
    #   - Mount->volume_id + Mount->export_id
    # If we gave arguments, find the subset of Mounts matching them:
    if ($param{filername}) {
        push @args, filername => $param{filername};
    }
    if ($param{physical_path}) {
        push @args, physical_path => $param{physical_path};
    }
    if (scalar @args) {
        foreach my $m (System::Disk::Mount->get( @args )) {
            ### Volume->delete mount: $m
            $m->delete or die "Failed to delete mount for volume: " . $self->id;
        }
    } else {
        # Otherwise remove all mounts and this Volume
        foreach my $m (System::Disk::Mount->get( volume_id => $self->id )) {
            ### Volume->delete mount: $m
            $m->delete or die "Failed to delete mount for volume: " . $self->id;
        }
        return $self->SUPER::delete();
    }
}

