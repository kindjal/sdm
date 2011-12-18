
package Sdm::Env::SDM_JIRA_HOSTNAME;

use strict;
use warnings;

class Sdm::Env::SDM_JIRA_HOSTNAME {
    is => 'Sdm::Env'
};

$ENV{SDM_JIRA_HOSTNAME} ||= "jira.gsc.wustl.edu";

1;
