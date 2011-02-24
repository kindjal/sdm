package System::Disk::User::Command;

use strict;
use warnings;

use System;

class System::Disk::User::Command {
    is => 'Command',
    is_abstract => 1,
    doc => 'work with disk users',
};

1;
