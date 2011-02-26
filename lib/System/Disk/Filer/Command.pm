package System::Disk::Filer::Command;

use strict;
use warnings;

use System;

class System::Disk::Filer::Command {
    is => 'Command',
    is_abstract => 1,
    doc => 'work with disk filers',
};

1;
