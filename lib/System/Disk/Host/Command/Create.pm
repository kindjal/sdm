package System::Disk::Host::Command::Create;

use strict;
use warnings;

use System;

class System::Disk::Host::Command::Create {
    is => 'System::Command::Base',
    has => [
        filer         => { is => 'System::Disk::Filer', 
                           id_by => 'filername',
                           constraint_name => 'HOST_FILER_FK',
                           shell_args_position => 1,
                           doc => "the filer which owns this host",
                        },
        hostname      => { is => 'Text', len => 255,
                            doc => "the name of the host owned by the filer"
                        },
    ],
    has_optional => [
        comments      => { is => 'Text', len => 255 },
        location      => { is => 'Text', len => 255 },
        os            => { is => 'Text', len => 255 },
        status        => { is => 'Number', default => 0 },
    ],
    doc => 'add a host to the set owned by a specific filer',
};

sub help_synopsis {
    return <<EOS
system disk host create myfiler1.mydomain.org myhost1.mydyomain.org --location "here!" --os "linx" --status 1 --comments "goody" 
EOS
}

sub help_detail {
    return <<EOS
This tool creates a host.  Blah blah blah details blah.
EOS
}

sub execute {
    my $self = shift;
    # FIXME: Is there a way in one statement to map params to $self->attributes
    my %params = (
        hostname  => $self->hostname,
        filername => $self->filername,
        comments  => $self->comments,
        location  => $self->location,
        status    => $self->status,
        os        => $self->os,
    );

    eval {
      System::Disk::Host->create(%params);
    };
    if ($@) {
        Carp::confess "Could not create host: $@";
    }

    return 1;
}

1;
