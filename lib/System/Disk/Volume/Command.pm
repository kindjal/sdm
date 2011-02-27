package System::Disk::Volume::Command;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command {
    is          => 'Command',
    doc         => 'work with disk volumes',
    is_abstract => 1,
};

1;
