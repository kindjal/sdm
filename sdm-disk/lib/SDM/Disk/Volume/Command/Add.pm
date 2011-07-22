
package SDM::Disk::Volume::Command::Add;

use strict;
use warnings;

use SDM;

class SDM::Disk::Volume::Command::Add {
    is => 'SDM::Command::Base',
    doc => 'add volumes',
    has => [
        name          => { is => 'Text' },
        filername     => { is => 'Text' },
        physical_path => { is => 'Text' },
    ],
    has_optional => [
        mount_point   => { is => 'Text' },
        total_kb      => { is => 'Number', default => 0 },
        used_kb       => { is => 'Number', default => 0 },
        disk_group    => { is => 'Text' },
    ],
};

sub execute {
    my $self = shift;

    my $param = {
        name          => $self->name,
        mount_point   => $self->mount_point,
        filername     => $self->filername,
        physical_path => $self->physical_path,
        total_kb      => $self->total_kb,
        used_kb       => $self->used_kb,
    };
    $param->{disk_group} = $self->disk_group if (defined $self->disk_group);

    return SDM::Disk::Volume->create( %$param );
}

1;
