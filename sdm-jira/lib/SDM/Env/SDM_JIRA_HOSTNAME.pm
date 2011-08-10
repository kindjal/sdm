
package SDM::Env::SDM_JIRA_HOSTNAME;

use strict;
use warnings;

class SDM::Env::SDM_JIRA_HOSTNAME {
    is => 'SDM::Env'
};

$ENV{SDM_JIRA_HOSTNAME} ||= "jira.gsc.wustl.edu";

1;
