
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use Test::More;
use Test::Output;
use Test::Exception;

use Data::Dumper;
#$Data::Dumper::Indent = 1;

use_ok( 'SDM' );

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-service-lib.pm";
require "$top/lib/SDM/Service/WebApp/Lsof.psgi";

my $content = '{"blade12-4-4.gsc.wustl.edu\t2859":{"uid":"0","timedelta":0,"time":1310672070,"name":["/usr/local/lsf/7.0/linux2.6-glibc2.3-x86_64/etc/melim.171901 (lsf:/vol/lsf)"],"username":"root","command":"melim"},"blade12-4-4.gsc.wustl.edu\t2703":{"uid":"0","timedelta":0,"time":1310672070,"name":["/usr/local/lsf/7.0/linux2.6-glibc2.3-x86_64/etc/res (lsf:/vol/lsf)"],"username":"root","command":"res"},"blade12-4-4.gsc.wustl.edu\t14966":{"uid":"12376","timedelta":0,"time":1310672070,"name":["/gscuser/mcallawa (nfs10home:/vol/home)"],"username":"mcallawa","command":"bash"},"blade12-4-4.gsc.wustl.edu\t22471":{"uid":"12236","timedelta":0,"time":1310672070,"name":["/gscuser/ebecker (nfs10home:/vol/home)"],"username":"ebecker","command":"screen"},"blade12-4-4.gsc.wustl.edu\t15046":{"uid":"12376","timedelta":0,"time":1310672070,"name":["/gscuser/mcallawa (nfs10home:/vol/home)","/gscmnt/gc2111/systems/.foo.swp (gpfs2:/vol/gc2111)"],"username":"mcallawa","command":"vi"},"blade12-4-4.gsc.wustl.edu\t2701":{"uid":"0","timedelta":0,"time":1310672070,"name":["/usr/local/lsf/7.0/linux2.6-glibc2.3-x86_64/etc/lim.041911 (lsf:/vol/lsf)"],"username":"root","command":"lim"},"blade12-4-4.gsc.wustl.edu\t2705":{"uid":"0","timedelta":0,"time":1310672070,"name":["/usr/local/lsf/7.0/linux2.6-glibc2.3-x86_64/etc/sbatchd (lsf:/vol/lsf)"],"username":"root","command":"sbatchd"},"blade12-4-4.gsc.wustl.edu\t2864":{"uid":"0","timedelta":0,"time":1310672070,"name":["/usr/local/lsf/7.0/linux2.6-glibc2.3-x86_64/etc/elim.gtmp (lsf:/vol/lsf)","/usr/local/lsf/7.0/linux2.6-glibc2.3-x86_64/etc/elim.gtmp (lsf:/vol/lsf)"],"username":"root","command":"elim.gtmp"},"blade12-4-4.gsc.wustl.edu\t15083":{"uid":"0","timedelta":0,"time":1310672070,"name":["/usr/local/lsf/7.0/linux2.6-glibc2.3-x86_64/etc/elim.gstat (lsf:/vol/lsf)"],"username":"root","command":"sleep"},"blade12-4-4.gsc.wustl.edu\t5082":{"uid":"0","timedelta":0,"time":1310672070,"name":["/usr/local/lsf/7.0/linux2.6-glibc2.3-x86_64/etc/elim.gtmp (lsf:/vol/lsf)"],"username":"root","command":"sleep"},"blade12-4-4.gsc.wustl.edu\t2863":{"uid":"0","timedelta":0,"time":1310672070,"name":["/usr/local/lsf/7.0/linux2.6-glibc2.3-x86_64/etc/elim.gstat (lsf:/vol/lsf)","/usr/local/lsf/7.0/linux2.6-glibc2.3-x86_64/etc/elim.gstat (lsf:/vol/lsf)"],"username":"root","command":"elim.gstat"},"blade12-4-4.gsc.wustl.edu\t2860":{"uid":"0","timedelta":0,"time":1310672070,"name":["/usr/local/lsf/7.0/linux2.6-glibc2.3-x86_64/etc/pim (lsf:/vol/lsf)"],"username":"root","command":"pim"}}';

my $app = SDM::Service::WebApp::Lsof->new();
$app->load_modules();
my @changes = $app->process($content);
warn "changes:\n" . Data::Dumper::Dumper @changes;

done_testing();
