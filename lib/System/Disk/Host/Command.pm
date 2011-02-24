package System::Disk::Host::Command;

use strict;
use warnings;

use System;

class System::Disk::Host::Command {
    is => 'Command',
    is_abstract => 1,
    doc => 'work with disk hosts',
};

1;
