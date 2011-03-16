
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
};

sub execute {
    my $self = shift;

    my $param = {
        mount_path    => $self->mount_path,
        filername     => $self->filername,
        physical_path => $self->physical_path,
    };

    my $volume = System::Disk::Volume->get( mount_path => $self->mount_path );
    if (defined $volume) {
        # If this volume is present, then add another Export and Mount
        unless (System::Disk::Filer->get( name => $self->filername )) {
            $self->error_message("Filer does not exist: " . $self->filername);
            return;
        }

        my $export = System::Disk::Export->get_or_create( filername => $self->filername, physical_path => $self->physical_path );
        unless ($export) {
            $self->error_message("Failed to create export: " . $self->filername . " " . $self->physical_path);
            return;
        }

        my $mount = System::Disk::Mount->get_or_create( volume_id => $volume->id, export_id => $export->id );
        unless ($mount) {
            $self->error_message("Failed to add mount for volume");
            return;
        }
        return $volume;
    }

    return System::Disk::Volume->create( $param );
}

1;
