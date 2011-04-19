package System::Rtm::Host::Command;

use strict;
use warnings;

use System;

class System::Rtm::Host::Command {
    is          => 'Command::Tree',
    doc         => 'work with RTM hosts',
    # leave as abstract until we know how to use this class
    is_abstract => 1,
};

use System::Command::Crud;
System::Command::Crud->init_sub_commands(
    target_class => 'System::Rtm::Host',
    target_name => 'host',
    list => { show => 'hostname' }
);

1;
