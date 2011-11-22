
package SDM::Asset::Software::Command;

use strict;
use warnings;

use SDM;

class SDM::Asset::Software::Command {
    is          => 'Command::Tree',
    doc         => 'SDM Asset',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Asset::Software',
    target_name => 'software',
    list => { show => 'manufacturer,product' },
);

1;
