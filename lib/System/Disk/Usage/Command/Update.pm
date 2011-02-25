package System::Disk::Usage::Command::Update;

use strict;
use warnings;

use System;
use System::Disk::Usage;

class System::Disk::Usage::Command::Update {
    is => 'System::Command::Base',
    doc => 'Queries volumes for usage'
};

sub help_brief {
    return 'Updates volume usage information';
}

sub help_synopsis {
    return <<EOS
Updates volume usage information
EOS
}

sub help_detail {
    return <<EOS
Updates volume usage information. Blah blah blah details blah.
EOS
}

sub execute {
    my $self = shift;

    my $result = System::Disk::Usage->new();
    unless ($result) {
        Carp::confess "Error during execute(): $!";
    }

    return 1;
}

1;
