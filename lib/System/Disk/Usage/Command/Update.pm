package System::Disk::Usage::Command::Update;

use strict;
use warnings;

use System;
use Class::MOP;

class System::Disk::Usage::Command::Update {
    is => 'System::Disk::Usage::Command',
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

    my $meta = Class::MOP::Class->initialize('System::Disk::Usage::Command::Update');
    foreach my $method ($meta->get_method_list()) {
      print "$method\n";
    }
    eval {
      System::Disk::Usage->create();
    };
    if ($@) {
        Carp::confess "Error during execute(): $@";
    }

    return 1;
}

1;
