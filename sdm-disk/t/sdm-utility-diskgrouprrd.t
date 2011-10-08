
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

use Test::More;
use Test::Output;
use Test::Exception;

use_ok( 'SDM' );
use_ok( 'SDM::Utility::DiskGroupRRD' );

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";

my $t = SDM::Disk::Lib->new();
ok( $t->testinit == 0, "ok: init db");
ok( $t->testdata == 0, "ok: add data");

my $u = SDM::Utility::DiskGroupRRD->create( loglevel => "DEBUG" );
lives_ok { $u->run(); } "run lived";

my $rrdpath = SDM::Env::SDM_DISK_RRDPATH->value;
my $group = "SYSTEMS_DEVELOPMENT"; # Set in sdm-disk-lib->testdata
my $rrdfile = $rrdpath . "/" . lc($group) . ".rrd";
ok( -f $rrdfile, "ok: rrd file made" );
unlink $rrdfile;

done_testing();
