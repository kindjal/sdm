package System::Disk::Array::Command::Create;

use strict;
use warnings;

use System;

class System::Disk::Array::Command::Create {
    is => 'System::Command::Base',
    has => [
        subject_class_name  => {
            is_constant => 1,
            value => 'System::Disk::Array',
        },
        show => { 
            default_value => 'array_id,model,size'
        },
    ],
};

sub help_brief {
    return 'Creates a volume';
}

sub help_synopsis {
    return 'Creates a volume';
}

sub help_detail {
    return <<EOS
This tool creates a volume.  Blah blah blah details blah.
EOS
}

sub execute {
    my $self = shift;
    my %params = (
        name => $self->name,
    );

    my $volume = System::Disk::Array->create(%params);
    unless ($volume) {
        Carp::confess "Could not create array: $!";
    }

    return 1;
}

1;
