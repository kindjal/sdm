
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

ok( SDM::Test::Lib->testinit == 0, "ok: init db");

my $content = '{"vm75.gsc.wustl.edu":{"vm75.gsc.wustl.edu\t18092":{"uid":"12376","name":["/gscuser/mcallawa (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"bash"},"vm75.gsc.wustl.edu\t18851":{"uid":"12376","name":["/gscuser/mcallawa/workspace/sdm/lib (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"lsof"},"vm75.gsc.wustl.edu\t27862":{"uid":"12376","name":["/gscuser/mcallawa/git/SDM (nfs10home:/vol/home/mcallawa)","/gscuser/mcallawa/git/SDM/sdm-service/t/.sdm-service-webapp-lsof.t.swp (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"vi"},"vm75.gsc.wustl.edu\t23913":{"uid":"12376","name":["/gscuser/mcallawa/git/SDM (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"bash"},"vm75.gsc.wustl.edu\t19162":{"uid":"12376","name":["/gscuser/mcallawa (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"bash"},"vm75.gsc.wustl.edu\t25266":{"uid":"12376","name":["/gscuser/mcallawa/workspace/sdm/lib (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"bash"},"vm75.gsc.wustl.edu\t27791":{"uid":"12376","name":["/gscuser/mcallawa/git/SDM/deploy (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"perl"},"vm75.gsc.wustl.edu\t25116":{"uid":"12376","name":["/gscuser/mcallawa/git/UR/lib/UR (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"bash"},"vm75.gsc.wustl.edu\t27794":{"uid":"12376","name":["/gscuser/mcallawa/git/SDM/deploy (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"snmpwalk"},"vm75.gsc.wustl.edu\t23845":{"uid":"12376","name":["/gscuser/mcallawa/git/SDM/deploy (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"bash"},"vm75.gsc.wustl.edu\t24613":{"uid":"12376","name":["/gscuser/mcallawa/workspace/dstat-0.7.0 (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"bash"},"vm75.gsc.wustl.edu\t23758":{"uid":"12376","name":["/gscuser/mcallawa/git/SDM/deploy (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"bash"},"vm75.gsc.wustl.edu\t23966":{"uid":"12376","name":["/gscuser/mcallawa (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"bash"},"vm75.gsc.wustl.edu\t18847":{"uid":"12376","name":["/gscuser/mcallawa/workspace/sdm/lib (nfs10home:/vol/home/mcallawa)"],"username":"mcallawa","command":"perl"}}}';

my $app = SDM::Service::WebApp::Lsof->new();
$app->load_modules();
my $changes = $app->process($content);
ok( scalar $changes == 14, "got changes" );

done_testing();
