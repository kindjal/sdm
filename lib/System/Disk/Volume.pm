
package System::Disk::Volume;

use strict;
use warnings;

use Date::Manip;
use System;
use Smart::Comments;

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
        exports       => { is => 'System::Disk::Export', reverse_as => 'volume' },
        physical_path => { via => 'exports' },
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

sub is_current {
    my $self = shift;
    my $vol_maxage = shift;

    print "is_current($vol_maxage) compare " . $self->last_modified . "\n";

    return 0 if (! defined $self->last_modified);

    return 0 if ($self->last_modified eq "0000-00-00 00:00:00");

    my $date0 = ParseDate($self->last_modified);
    return 0 if (! defined $date0);

    my $err;
    my $date1 = ParseDate(scalar gmtime());
    my $calc = DateCalc($date0,$date1,\$err);

    die "Error in DateCalc: $date0, $date1, $err\n" if ($err);
    die "Error in DateCalc: $date0, $date1, $err\n" if (! defined $calc);

    my $delta = Delta_Format($calc,0,'%st');

    print "is_current: delta $delta\n";

    return 0 if (! defined $delta);

    return 1
        if $delta < $vol_maxage;

    return 0;
}

sub validate_volumes {
    # FIXME: Add code to validate volumes
    # similar to DiskUsage::Cache
    my $self = shift;
    return 0;
}

sub purge {
    # FIXME: Add code to remove stale volumes
    # similar to DiskUsage::Cache
    my $self = shift;
    return 0;
}

sub get_or_create {
    my ($self,$param) = @_;
    ### Volume->get_or_create: $param
    my $volume = System::Disk::Volume->get( mount_path => $param->{mount_path}, filername => $param->{filername}, physical_path => $param->{physical_path} );
    unless ($volume) {
        $volume = $self->create( $param );
    }
    return $volume;
}

sub create {
    my ($self,$param) = @_;
    ### Volume->create: $param
    # A fully defined Volume has, in order:
    #   - Filer->name
    #   - Export->filername + Export->physical_path
    #   - Volume->mount_path
    #   - Mount->volume_id + Mount->export_id
    my $volume = System::Disk::Volume->get( mount_path => $param->{mount_path}, filername => $param->{filername}, physical_path => $param->{physical_path} );
    if ($volume) {
        # This exact volume + mount exists
        $self->error_message("Volume already exists");
        return;
    }
    ### Volume->create get volume: $volume

    # The exact volume doesn't exist, so make sure we have the Filer
    my $filer = System::Disk::Filer->get_or_create( name => $param->{filername} );
    unless ($filer) {
        $self->error_message("Failed to add filer: " . $param->{filername});
        return;
    }
    ### Volume->create get filer: $filer

    # Now make sure the Filer has the Export
    my $export = System::Disk::Export->get_or_create( filername => $param->{filername}, physical_path => $param->{physical_path} );
    unless ($export) {
        $self->error_message("Failed to add export: '" . $param->{filername} ." " . $param->{physical_path} );
        return;
    }
    ### Volume->create get export: $export

    # Now that we're sure that a Filer and Export exist, and that we don't already
    # have this exact Volume, we can add the Volume and/or Mount.
    $volume = System::Disk::Volume->get( mount_path => $param->{mount_path} );
    unless ($volume) {
        # No volume at all at this mount, add the volume then the mount.
        $volume = $self->SUPER::create( mount_path => $param->{mount_path} );
        unless ($volume) {
            $self->error_message("Unable to create volume");
            return;
        }
    }
    ### Volume->create create volume: $volume

    # FIXME: This commit() should not be required.  UR bug?
    UR::Context->commit();
    ### UR commit here

    # Now that we have a Volume, ensure there's a mount (bridge table)
    # Mount is a bridge table between Volume and Filer.
    my $mount  = System::Disk::Mount->get_or_create( volume_id => $volume->id, export_id => $export->id );
    unless ($mount) {
        $self->error_message("Failed to add mount for volume");
        return;
    }
    ### Volume->create get_or_create mount: $mount

    ### Volume->create returns volume: $volume
    return $volume;
}

sub delete {
    my $self = shift;
    ### Volume->delete: $self
    # Remove the Export entries, then the Mount entries, then the Volume
    #   - Export->filername + Export->physical_path
    #   - Volume->mount_path
    #   - Mount->volume_id + Mount->export_id
    foreach my $m (System::Disk::Mount->get( volume_id => $self->id )) {
        ### Volume->delete mount: $m
        $m->delete or die "Failed to delete mount for volume: " . $self->id;
    }
    return $self->SUPER::delete();
}

