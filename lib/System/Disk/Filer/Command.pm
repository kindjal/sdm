package System::Disk::Array::Command;

use strict;
use warnings;

use System;

class System::Disk::Array::Command {
    is => 'Command',
    is_abstract => 1,
    doc => 'work with disk filers',
};

1;
