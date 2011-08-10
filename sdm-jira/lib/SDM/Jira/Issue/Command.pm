
package SDM::Jira::Issue::Command;

use strict;
use warnings;

use SDM;

class SDM::Jira::Issue::Command {
    is          => 'Command::Tree',
    doc         => 'Display Jira issues',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Jira::Issue',
    target_name => 'issue',
    list => { show => 'pkey,assignee,summary' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
