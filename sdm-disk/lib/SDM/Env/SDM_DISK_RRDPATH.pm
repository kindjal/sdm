
package SDM::Env::SDM_DISK_RRDPATH;

use strict;
use warnings;
use File::Basename qw/dirname/;

my $path = SDM::Disk->__meta__->module_path;
$path = dirname $path;
$path .= "/View/Resource/Html/rrd";

$ENV{SDM_DISK_RRDPATH} ||= $path;

class SDM::Env::SDM_DISK_RRDPATH {
    is => "SDM::Env"
};

1;
