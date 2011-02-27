package System::Disk::Usage::Command;

use strict;
use warnings;

use System;

class System::Disk::Usage::Command {
    is          => 'System::Command::Base',
    doc         => 'work with disk usage',
    is_abstract => 1,
};

1;
