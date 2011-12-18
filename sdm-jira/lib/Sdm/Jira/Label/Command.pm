
package Sdm::Jira::Label::Command;

use strict;
use warnings;

use Sdm;

class Sdm::Jira::Label::Command {
    is          => 'Command::Tree',
    doc         => 'Display Jira labels',
};

use Sdm::Command::Crud;
Sdm::Command::Crud->init_sub_commands(
    target_class => 'Sdm::Jira::Label',
    target_name => 'issue',
    list => { show => 'id,fieldid,label' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
