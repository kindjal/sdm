
package SDM::Env::SDM_RTM_HOSTNAME;

use strict;
use warnings;

class SDM::Env::SDM_RTM_HOSTNAME {
    is => 'SDM::Env'
};

$ENV{SDM_RTM_HOSTNAME} ||= "rtm.gsc.wustl.edu";

1;
