
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
        total_kb      => { is => 'Number', default => 0 },
        used_kb       => { is => 'Number', default => 0 },
        disk_group    => { is => 'Text' },
    ],
};

sub execute {
    my $self = shift;

    my $param = {
        mount_path    => $self->mount_path,
        filername     => $self->filername,
        physical_path => $self->physical_path,
        total_kb      => $self->total_kb,
        used_kb       => $self->used_kb,
    };
    $param->{disk_group} = $self->disk_group if (defined $self->disk_group);

    return System::Disk::Volume->create( %$param );
}

1;
