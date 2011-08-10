
package SDM::DataSource::Jira;

use strict;
use warnings;

use SDM;

my $hostname = $ENV{SDM_JIRA_HOSTNAME};

class SDM::DataSource::Jira {
    is => [ 'UR::DataSource::MySQL' ],
    has_constant => [
        server => { default_value => "dbname=jira;host=$hostname" },
        owner  => { default_value => 'jira_user' },
        login  => { default_value => 'jira_user' },
        #auth   => { default_value => 'm23$4xy1z' },
        auth   => { default_value => 'jira_pass' },
    ]
};

1;
