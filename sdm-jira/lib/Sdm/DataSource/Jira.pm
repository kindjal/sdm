
package Sdm::DataSource::Jira;

use strict;
use warnings;

use Sdm;

my $hostname = $ENV{SDM_JIRA_HOSTNAME};

class Sdm::DataSource::Jira {
    is => [ 'UR::DataSource::MySQL' ],
    has_constant => [
        server => { default_value => "dbname=jira;host=$hostname" },
        owner  => { default_value => 'jira_user' },
        login  => { default_value => 'jira_user' },
        auth   => { default_value => 'jira_pass' },
    ]
};

1;
