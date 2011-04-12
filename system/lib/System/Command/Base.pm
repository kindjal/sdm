package System::Command::Base;

use strict;
use warnings;

use System;

class System::Command::Base {
    is => 'Command::Tree',
    is_abstract => 1,
};

1;
