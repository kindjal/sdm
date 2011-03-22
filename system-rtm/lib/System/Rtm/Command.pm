package System::Rtm::Command;

use System;
use strict;
use warnings;

class System::Rtm::Command {
    is          => 'System::Command::Base',
    doc         => 'Work with RTM',
    is_abstract => 1,
};

1;
