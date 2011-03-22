package System::Disk::Command;

use System;
use strict;
use warnings;

class System::Disk::Command {
    is          => 'System::Command::Base',
    doc         => 'Work with disk',
    is_abstract => 1,
};

1;
