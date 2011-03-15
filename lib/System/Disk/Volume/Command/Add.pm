
package System::Disk::Volume::Command::Add;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command::Add {
    is => 'System::Command::Base',
    doc => 'add volumes.',
    has => [
        mount_path => { is => 'Text' },
        filerpath  => { is => 'Text' },
    ],
};

sub execute {
    my $self = shift;
    $self->prepare_logger();
    my ($filername, $physical_path) = split(/\s+/, $self->filerpath );
    my $fp = System::Disk::Filerpath->get( { filername => $filername, physical_path => $physical_path } );
    die "Filer '$filername' has no export path '$physical_path'"
        if (! defined $fp);

    my $param = [
        mount_path => $self->mount_path,
        filerpaths => [ "$filername\t$physical_path"  ],
    ];
    my $result = System::Disk::Volume->create( $param );
}

1;
