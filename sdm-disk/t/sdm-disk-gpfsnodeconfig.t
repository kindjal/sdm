
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

use SDM;

use Test::More;
use Test::Output;
use Test::Exception;

unless ($ENV{SDM_GENOME_INSTITUTE_NETWORKS}) {
    plan skip_all => "Don't assume we can reach SNMP on named hosts for non GI networks";
}

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-lib.pm";
ok( SDM::Test::Lib->testinit == 0, "init db");
ok( SDM::Test::Lib->testdata == 0, "data db");

my $res;
my @res;

@res = SDM::Disk::Host->get( hostname => 'linuscs107' );
$res = shift @res;
$res = $res->gpfs_node_config;

ok( ref $res eq "SDM::Disk::GpfsNodeConfig", "object made correctly");
ok( ref $res->filer eq 'SDM::Disk::Filer', "filer object related");

ok( defined $res->filername, "attr set" );
ok( defined $res->filer, "attr set" );
ok( defined $res->gpfsNodeConfigName, "attr set" );
ok( defined $res->gpfsNodeType, "attr set" );
ok( defined $res->gpfsNodeAdmin, "attr set" );
ok( defined $res->gpfsNodePagePoolL, "attr set" );
ok( defined $res->gpfsNodePagePoolH, "attr set" );
ok( defined $res->gpfsNodePrefetchThreads, "attr set" );
ok( defined $res->gpfsNodeMaxMbps, "attr set" );
ok( defined $res->gpfsNodeMaxFilesToCache, "attr set" );
ok( defined $res->gpfsNodeMaxStatCache, "attr set" );
ok( defined $res->gpfsNodeWorker1Threads, "attr set" );
ok( defined $res->gpfsNodeDmapiEventTimeout, "attr set" );
ok( defined $res->gpfsNodeDmapiMountTimeout, "attr set" );
ok( defined $res->gpfsNodeDmapiSessFailureTimeout, "attr set" );
ok( defined $res->gpfsNodeNsdServerWaitTimeWindowOnMount, "attr set" );
ok( defined $res->gpfsNodeNsdServerWaitTimeForMount, "attr set" );
ok( defined $res->gpfsNodeUnmountOnDiskFail, "attr set" );

done_testing();
