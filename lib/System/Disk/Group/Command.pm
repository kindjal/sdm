package System::Disk::Group::Command;

use strict;
use warnings;

use System;

class System::Disk::Group::Command {
    is => 'Command',
    is_abstract => 1,
    doc => 'work with disk groups',
};

1;
