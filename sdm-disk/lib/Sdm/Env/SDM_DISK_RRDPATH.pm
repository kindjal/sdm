
package Sdm::Env::SDM_DISK_RRDPATH;

use strict;
use warnings;
use File::Basename qw/dirname/;

my $path = Sdm::Disk->__meta__->module_path;
$path = dirname $path;
$path .= "/View/Resource/Html/rrd";

$ENV{SDM_DISK_RRDPATH} ||= $path;

class Sdm::Env::SDM_DISK_RRDPATH {
    is => "Sdm::Env"
};

1;
