package System::Disk::Assignment::Command;

use strict;
use warnings;

use System;

class System::Disk::Assignment::Command {
    is          => 'Command',
    doc         => 'work with disk assignments',
    is_abstract => 1,
};

sub command_name {
    my $class = ref($_[0]) || $_[0];
    return $class->SUPER::command_name unless $class eq __PACKAGE__;
    return 'genome disk assignment';
}

sub command_name_brief {
    my $class = ref($_[0]) || $_[0];
    return $class->SUPER::command_name_brief unless $class eq __PACKAGE__;
    return 'assignment';
}

1;
