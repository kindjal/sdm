
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use Sdm;

use Test::More;
use Test::Output;
use Test::Exception;

unless ($ENV{SDM_GENOME_INSTITUTE_NETWORKS}) {
    plan skip_all => "Test only valid on GI networks";
}


# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
if ($top =~ /deploy/) {
    require "$top/t/sdm-disk-lib.pm";
} else {
    require "$top/../sdm-disk/t/sdm-disk-lib.pm";
}
ok( Sdm::Disk::Lib->has_gpfs_snmp == 1, "has gpfs");
ok( Sdm::Disk::Lib->testinit == 0, "init db");
ok( Sdm::Disk::Lib->testdata == 0, "data db");

my $res;

$res  = Sdm::Gpfs::GpfsClusterConfig->get( filername => 'fakefiler' );
ok( ! defined $res, "fake filer returns undef" );

$res  = Sdm::Gpfs::GpfsClusterConfig->get( filername => 'gpfs-dev' );
ok( ref $res eq "Sdm::Gpfs::GpfsClusterConfig", "object made correctly");
ok( defined $res->id, "object created ok");

ok( $res->filername eq 'gpfs-dev', "filername set");
ok( ref $res->filer eq 'Sdm::Disk::Filer', "filer object related");

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
