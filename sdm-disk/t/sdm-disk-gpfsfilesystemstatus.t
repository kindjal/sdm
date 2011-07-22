
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
require "$top/t/sdm-disk-lib.pm";
ok( SDM::Test::Lib->has_gpfs_snmp == 1, "gpfs ok");
ok( SDM::Test::Lib->testinit == 0, "init db");
ok( SDM::Test::Lib->testdata == 0, "data db");

my $res;
my @res;

@res = SDM::Disk::GpfsFileSystemStatus->get( filername => 'fakefiler' );
ok( ! @res, "fake filer returns undef" );

@res = SDM::Disk::GpfsFileSystemStatus->get( filername => 'gpfs-dev' );
$res = shift @res;

ok( ref $res eq "SDM::Disk::GpfsFileSystemStatus", "object made correctly");
ok( ref $res->filer eq 'SDM::Disk::Filer', "filer object related");

ok( defined $res->filername, "attr set" );
ok( defined $res->filer, "filer attr set" );
#ok( defined $res->volume, "volume attr set" );
ok( defined $res->gpfsFileSystemName, "attr set" );
ok( defined $res->gpfsFileSystemXstatus, "attr set" );
ok( defined $res->gpfsFileSystemTotalSpaceL, "attr set" );
ok( defined $res->gpfsFileSystemTotalSpaceH, "attr set" );
ok( defined $res->gpfsFileSystemNumTotalInodesL, "attr set" );
ok( defined $res->gpfsFileSystemNumTotalInodesH, "attr set" );
ok( defined $res->gpfsFileSystemFreeSpaceL, "attr set" );
ok( defined $res->gpfsFileSystemFreeSpaceH, "attr set" );
ok( defined $res->gpfsFileSystemNumFreeInodesL, "attr set" );
ok( defined $res->gpfsFileSystemNumFreeInodesH, "attr set" );

done_testing();
