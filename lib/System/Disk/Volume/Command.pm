package System::Disk::Volume::Command;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command {
    is => 'Command',
    is_abstract => 1,
    doc => 'work with disk volumes',
};

############################################

sub command_name {
    my $class = ref($_[0]) || $_[0];
    return $class->SUPER::command_name unless $class eq __PACKAGE__;
    return 'genome disk volume';
}

sub command_name_brief {
    my $class = ref($_[0]) || $_[0];
    return $class->SUPER::command_name_brief unless $class eq __PACKAGE__;
    return 'volume';
}

############################################




1;

