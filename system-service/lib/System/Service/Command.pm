package System::Service::Command;

use System;
use strict;
use warnings;

class System::Service::Command {
    is          => 'System::Command::Base',
    doc         => 'Work with services',
    is_abstract => 1,
};

1;
