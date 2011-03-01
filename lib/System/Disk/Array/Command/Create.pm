package System::Disk::Array::Command::Create;

use strict;
use warnings;

use System;

class System::Disk::Array::Command::Create {
    is => 'System::Command::Base',
    has => [
        name  => { is => 'Text', len => 255 },
        host  => { is => 'System::Disk::Host', id_by => 'hostname', constraint_name => 'ARRAY_HOST_FK' },
    ],
    has_optional_param => [
        model => { is => 'Text', len => 255 },
        type  => { is => 'Text', len => 255 },
        size  => { is => 'Integer' },
    ],
};

sub help_brief {
    return 'Creates an array';
}

sub help_synopsis {
    return <<EOS
Creates an array
EOS
}

sub help_detail {
    return <<EOS
This tool creates an array.  Blah blah blah details blah.
EOS
}

sub execute {
    my $self = shift;
    my %params = (
        name  => $self->name,
        hostname => $self->hostname,
        model => $self->model,
        size => $self->size,
        type => $self->type,
    );

    eval {
      System::Disk::Array->create(%params);
    };
    if ($@) {
      Carp::confess "Could not create array: $!";
    }

    return 1;
}

1;
