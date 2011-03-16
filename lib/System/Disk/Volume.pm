
package System::Disk::Volume;

use strict;
use warnings;

use Date::Manip;
use System;

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
        exports       => { is => 'System::Disk::Export', reverse_as => 'volume' },
        filername     => { via => 'mounts' },
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

sub create {
    my ($self,$param) = @_;
    warn "debug: " . Data::Dumper::Dumper $param;
    delete $param->{filername};
    delete $param->{physical_path};

    my $mount = System::Disk::Mount->get( mount_path => $param->{mount_path}, filername => $param->{filername}, physical_path => $param->{physical_path} );
    if (defined $mount) {
        $self->warning_message("Volume already exists: $param->{mount_path} -> $param->{filername} $param->{physical_path}" );
        return;
    }

    my $export = System::Disk::Export->get_or_create( filername => $param->{filername}, physical_path => $param->{physical_path} );
    unless ($export) {
        $self->error_message("Filer '" . $param->{filername} ."' has no export '" . $param->{physical_path} ."' and we failed to create one.");
        return;
    }

    # Many volumes may exist with the same mount_path, but only one
    #   mount_path + ( filername + physical_path )
    my $volume = $self->SUPER::create( $param );
    die "Unable to create volume: $!"
        if (! defined $volume);

    # FIXME: This commit() should not be required.  UR bug?
    UR::Context->commit();

    # Mount is a bridge table between Volume and Filer.
    $mount  = System::Disk::Mount->create( volume_id => $volume->id, export_id => $export->id );

    return $volume;
}

sub delete {
    my $self = shift;
    # Remove bridge table entires from Mount first
    # Then delete the Volume
    foreach my $m (System::Disk::Mount->get( volume_id => $self->id )) {
        $m->delete() or die "Failed to delete mount for volume: " . $self->id;
    }
    return $self->SUPER::delete();
}

