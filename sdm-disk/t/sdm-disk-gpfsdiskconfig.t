
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

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";
ok( SDM::Test::Lib->has_gpfs_snmp == 1, "gpfs ok");
ok( SDM::Test::Lib->testinit == 0, "init db");
ok( SDM::Test::Lib->testdata == 0, "data db");

my $res;
my @res;

@res = SDM::Disk::GpfsDiskConfig->get( filername => 'fakefiler' );
ok( ! @res, "fake filer returns undef" );

@res = SDM::Disk::GpfsDiskConfig->get( filername => 'gpfs-dev' );
$res = shift @res;
ok( ref $res eq "SDM::Disk::GpfsDiskConfig", "object made correctly");
ok( $res->filername eq 'gpfs-dev', "filername set");
ok( ref $res->filer eq 'SDM::Disk::Filer', "filer object related");
#ok( ref $res->volume eq 'SDM::Disk::Volume', "filer object related");

ok( defined $res->filername, "attr set" );
ok( defined $res->gpfsDiskConfigName, "attr set");
ok( defined $res->gpfsDiskConfigFSName, "attr set");
ok( defined $res->gpfsDiskConfigStgPoolName, "attr set");
ok( defined $res->gpfsDiskMetadata, "attr set");
ok( defined $res->gpfsDiskData, "attr set");
ok( defined $res->mount_path, "attr set");

done_testing();
