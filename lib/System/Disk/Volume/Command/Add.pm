
package System::Disk::Volume::Command::Add;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command::Add {
    is => 'System::Command::Base',
    doc => 'add volumes',
    has => [
        mount_path    => { is => 'Text' },
        filername     => { is => 'Text' },
        physical_path => { is => 'Text' },
    ],
    has_optional => [
        total_kb      => { is => 'Number' },
        used_kb       => { is => 'Number' },
        disk_group    => { is => 'Text' },
    ],
};

sub execute {
    my $self = shift;

    my $param = {
        mount_path    => $self->mount_path,
        filername     => $self->filername,
        physical_path => $self->physical_path,
    };
    $param->{total_kb} = $self->total_kb ? $self->total_kb : 0;
    $param->{used_kb} = $self->used_kb ? $self->used_kb : 0;
    $param->{disk_group} = $self->disk_group if (defined $self->disk_group);

    my $volume = System::Disk::Volume->get( mount_path => $self->mount_path );
    if (defined $volume) {
        # If this volume is present, then add another Export and Mount
        my $filer = System::Disk::Filer->get_or_create( name => $self->filername );
        unless ($filer) {
            $self->error_message("Filer to create filer: " . $self->filername);
            return;
        }

        # We have a Volume and Filer, ensure the Filer has an Export
        my $export = System::Disk::Export->get_or_create( filername => $self->filername, physical_path => $self->physical_path );
        unless ($export) {
            $self->error_message("Failed to create export: " . $self->filername . " " . $self->physical_path);
            return;
        }

        # We have a Volume, Filer, and Export, ensure we have a Mount
        my $mount = System::Disk::Mount->get_or_create( volume_id => $volume->id, export_id => $export->id );
        unless ($mount) {
            $self->error_message("Failed to add mount for volume");
            return;
        }

        # Now we have all we wanted.
        return $volume;
    }

    return System::Disk::Volume->create( $param );
}

1;
