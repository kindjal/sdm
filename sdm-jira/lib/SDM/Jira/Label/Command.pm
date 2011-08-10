
package SDM::Jira::Label::Command;

use strict;
use warnings;

use SDM;

class SDM::Jira::Label::Command {
    is          => 'Command::Tree',
    doc         => 'Display Jira labels',
};

use SDM::Command::Crud;
SDM::Command::Crud->init_sub_commands(
    target_class => 'SDM::Jira::Label',
    target_name => 'issue',
    list => { show => 'id,fieldid,label' },
    delete => { do_not_init => 1, },
    update => { do_not_init => 1, },
    add    => { do_not_init => 1, },
);

1;
