
package Sdm::Jira::Issue::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Jira::Issue::Command {
    is          => 'Command::Tree',
    doc         => 'Display Jira issues',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Jira::Issue',
    target_name => 'issue',
    list => { show => 'pkey,assignee,summary' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
