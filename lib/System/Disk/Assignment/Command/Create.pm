package System::Disk::Assignment::Command::Create;

use strict;
use warnings;

use System;

class System::Disk::Assignment::Command::Create {
    is => 'System::Command::Base',
    has => [
      group => { is => 'System::Disk::Group', id_by => 'name', constraint_name => 'VOLUME_GROUP_GROUP_FK' },
      volume => { is => 'System::Disk::Volume', id_by => 'volume_id', constraint_name => 'VOLUME_GROUP_VOLUME_FK' },
    ],
};

sub execute {
    my $self = shift;
    my %params = (
        group => $self->group,
        volume => $self->volume,
    );

    eval {
        System::Disk::Assignment->create(%params);
    };
    if ($@) {
        Carp::confess "Could not assign volume to group: $@";
    }

    return 1;
}

1;
