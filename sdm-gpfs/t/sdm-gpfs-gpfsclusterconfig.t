
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use SDM;

use Test::More;
use Test::Output;
use Test::Exception;

unless ($ENV{SDM_GENOME_INSTITUTE_NETWORKS}) {
    plan skip_all => "Test only valid on GI networks";
}


# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/../sdm-disk/t/sdm-disk-lib.pm";

ok( SDM::Test::Lib->has_gpfs_snmp == 1, "has gpfs");
ok( SDM::Test::Lib->testinit == 0, "init db");
ok( SDM::Test::Lib->testdata == 0, "data db");

my $res;

$res  = SDM::Gpfs::GpfsClusterConfig->get( filername => 'fakefiler' );
ok( ! defined $res, "fake filer returns undef" );

$res  = SDM::Gpfs::GpfsClusterConfig->get( filername => 'gpfs-dev' );
ok( ref $res eq "SDM::Gpfs::GpfsClusterConfig", "object made correctly");
ok( defined $res->id, "object created ok");

ok( $res->filername eq 'gpfs-dev', "filername set");
ok( ref $res->filer eq 'SDM::Disk::Filer', "filer object related");

ok( defined $res->gpfsClusterConfigName, "attr set" );
ok( defined $res->gpfsClusterUidDomain, "attr set" );
ok( defined $res->gpfsClusterRemoteShellCommand, "attr set" );
ok( defined $res->gpfsClusterRemoteFileCopyCommand, "attr set" );
ok( defined $res->gpfsClusterPrimaryServer, "attr set" );
ok( defined $res->gpfsClusterSecondaryServer, "attr set" );
ok( defined $res->gpfsClusterMaxBlockSize, "attr set" );
ok( defined $res->gpfsClusterDistributedTokenServer, "attr set" );
ok( defined $res->gpfsClusterFailureDetectionTime, "attr set" );
ok( defined $res->gpfsClusterTCPPort, "attr set" );
ok( defined $res->gpfsClusterMinMissedPingTimeout, "attr set" );
ok( defined $res->gpfsClusterMaxMissedPingTimeout, "attr set" );
done_testing();