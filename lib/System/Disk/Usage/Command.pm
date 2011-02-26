package System::Disk::Usage::Command;

use strict;
use warnings;

use System;

class System::Disk::Usage::Command {
    is => 'System::Command::Base',
    is_abstract => 1,
    doc => 'work with disk usage',
};

1;
