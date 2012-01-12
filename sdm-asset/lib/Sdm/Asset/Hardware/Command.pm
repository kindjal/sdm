
package Sdm::Asset::Hardware::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Asset::Hardware::Command {
    is          => 'Command::Tree',
    doc         => 'Sdm Asset',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Asset::Hardware',
    target_name => 'hardware',
    list => { show => 'hostname,tag,manufacturer,model,description,comments,warranty_expires' },
);

1;
