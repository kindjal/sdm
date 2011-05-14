package SDM::Rtm::Host::Command;

use strict;
use warnings;

use SDM;

class SDM::Rtm::Host::Command {
    is          => 'Command::Tree',
    doc         => 'work with RTM hosts',
    # leave as abstract until we know how to use this class
    is_abstract => 1,
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Rtm::Host',
    target_name => 'host',
    list => { show => 'hostname' }
);

1;
