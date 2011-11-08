
package SDM::Asset::Hardware::Command;

use strict;
use warnings;

use SDM;

class SDM::Asset::Hardware::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Asset',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Asset::Hardware',
    target_name => 'hardware',
    list => { show => 'manufacturer,model' },
);

1;
