
package System::Env::SYSTEM_DISK_RRDPATH;

use strict;
use warnings;
use File::Basename qw/dirname/;

my $path = System::Disk->__meta__->module_path;
$path = dirname $path;
$path .= "/View/Resource/Html/rrd";

if ($ENV{SYSTEM_DEPLOYMENT} eq 'testing') {
    $ENV{SYSTEM_DISK_RRDPATH} ||= $path;
} else {
    $ENV{SYSTEM_DISK_RRDPATH} ||= "/var/cache/sdm/disk/rrd";
}

class System::Env::SYSTEM_DISK_RRDPATH {
    is => "System::Env"
};

1;
