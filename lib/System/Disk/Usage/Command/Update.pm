package System::Disk::Usage::Command::Update;

use strict;
use warnings;

use System;

class System::Disk::Usage::Command::Update {
    is => 'System::Command::Base',
    doc => 'Queries and stores volume usage data'
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

    eval {
      System::Disk::Usage->main();
    };
    if ($@) {
        Carp::confess "Error during execute(): $@";
    }

    return 1;
}

1;
