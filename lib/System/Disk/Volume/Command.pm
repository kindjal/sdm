package System::Disk::Volume::Command;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command {
    is => 'Command',
    is_abstract => 1,
    doc => 'work with disk volumes',
};

1;
