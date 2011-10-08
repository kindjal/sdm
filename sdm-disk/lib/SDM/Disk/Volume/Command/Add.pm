
package SDM::Disk::Volume::Command::Add;

use strict;
use warnings;

use SDM;

class SDM::Disk::Volume::Command::Add {
    is => 'SDM::Command::Base',
    doc => 'add volumes',
    has => [
        filername     => { is => 'Text' },
        physical_path => { is => 'Text' },
    ],
    has_optional => [
        mount_point   => { is => 'Text' },
        total_kb      => { is => 'Number' },
        used_kb       => { is => 'Number' },
        disk_group    => { is => 'Text' },
    ],
};

sub execute {
    my $self = shift;

    my $param = {
        filername     => $self->filername,
        physical_path => $self->physical_path,
    };
    $param->{mount_point} = $self->mount_point if (defined $self->mount_point);
    $param->{disk_group} = $self->disk_group if (defined $self->disk_group);
    $param->{total_kb} = $self->total_kb if (defined $self->total_kb);
    $param->{used_kb} = $self->total_kb if (defined $self->used_kb);

    return SDM::Disk::Volume->create( %$param );
}

1;
