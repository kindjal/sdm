package System::Rtm::Grid::Command;

use strict;
use warnings;

use System;

class System::Rtm::Grid::Command {
    is          => 'System::Command::Base',
    doc         => 'work with RTM grid jobs',
    is_abstract => 1
};

1;
