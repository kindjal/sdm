
package Sdm::Env::SDM_RTM_HOSTNAME;

use strict;
use warnings;

class Sdm::Env::SDM_RTM_HOSTNAME {
    is => 'Sdm::Env'
};

$ENV{SDM_RTM_HOSTNAME} ||= "rtm.gsc.wustl.edu";

1;
