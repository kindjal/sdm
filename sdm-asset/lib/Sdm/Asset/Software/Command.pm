
package Sdm::Asset::Software::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Asset::Software::Command {
    is          => 'Command::Tree',
    doc         => 'Sdm Asset',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Asset::Software',
    target_name => 'software',
    list => { show => 'manufacturer,product' },
);

1;
