
package Sdm::Jira::Issuestatus::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Jira::Issuestatus::Command {
    is          => 'Command::Tree',
    doc         => 'List Jira issuestatus items',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Jira::Issuestatus',
    target_name => 'issuestatus',
    list => { show => 'id,pname,description' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
