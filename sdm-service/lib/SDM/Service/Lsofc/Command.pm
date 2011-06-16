package SDM::Service::Lsofc::Command;

use strict;
use warnings;

use SDM;

class SDM::Service::Lsofc::Command {
    #is          => 'Command::V2',
    is          => 'Command::Tree',
    doc         => 'run lsof client',
};

1;
