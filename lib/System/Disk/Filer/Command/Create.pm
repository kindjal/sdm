package System::Disk::Filer::Command::Create;

use strict;
use warnings;

use System;

class System::Disk::Filer::Command::Create {
    is => 'System::Command::Base',
    has => [
        name          => { is => 'Text', len => 255 },
    ],
    has_optional => [
        status        => { is => 'Number' },
        comments      => { is => 'Text', len => 255 },
        filesystem    => { is => 'Text', len => 255 },
        created       => { is => 'DATE' },
        last_modified => { is => 'DATE' },
    ],
};

sub help_brief {
    return 'Creates a filer';
}

sub help_synopsis {
    return <<EOS
Creates a filer
EOS
}

sub help_detail {
    return <<EOS
This tool creates a filer.  Blah blah blah details blah.
EOS
}

sub execute {
    my $self = shift;
    my %params = (
        name => $self->name,
        status => $self->status,
        comments => $self->comments,
        filesystem => $self->filesystem,
    );

    eval {
      System::Disk::Filer->create(%params);
    };
    if ($@) {
        Carp::confess "Could not create filer: $@";
    }

    return 1;
}

1;
