
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

use Sdm;

use Test::More;
use Test::Output;
use Test::Exception;

my $res;
my $params;

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";
ok( Sdm::Disk::Lib->testinit == 0, "ok: init db");

# Test insufficient creation params
my @params = ();
ok( ! defined Sdm::Disk::Volume->create( @params ), "properly fail to create volume with empty param" );
@params = ( filername => 'nfs11' );
ok( ! defined Sdm::Disk::Volume->create( @params ), "properly fail to create volume with no physical_path" );

# Fail to create a volume without a filer
@params = ( mount_path => '/gscmnt/sata800', physical_path => '/vol/sata800', total_kb => 2, used_kb => 1 );
$res = Sdm::Disk::Volume->create( @params );
ok( ! defined $res, "properly failed to create volume without filer");

ok( my $gpfs = Sdm::Disk::Filer->create( name => 'gpfs' ), "created test filer ok");
ok( my $array = Sdm::Disk::Array->create( name => 'nsams2k1' ), "created test array ok");
ok( my $host = Sdm::Disk::Host->create( hostname => 'linuscs103' ), "created test host ok");

my $r = $array->assign( "linuscs103" );
isa_ok( $r, "Sdm::Disk::HostArrayBridge" );
$r = $host->assign( "gpfs" );
isa_ok( $r, "Sdm::Disk::FilerHostBridge" );

# Create test group to test with
ok( defined Sdm::Disk::Group->create( name => 'INFO_GENOME_MODELS' ), "created test group ok");

# Try to create with wrong volume
@params = ( filername => 'gpfsX', mount_path => '/gscmnt/sata801', physical_path => '/vol/sata801', disk_group => 'INFO_GENOME_MODELS', total_kb => 2, used_kb => 1 );
$res = Sdm::Disk::Volume->create( @params );
ok( ! defined $res, "properly prevent volume with wrong filername");

# Test proper creation
@params = ( filername => 'gpfs', mount_path => '/gscmnt/sata802', physical_path => '/vol/sata802', disk_group => 'INFO_GENOME_MODELS', total_kb => 2, used_kb => 1 );
$res = Sdm::Disk::Volume->create( @params );
ok( defined $res->id, "properly created new volume");
UR::Context->commit();
done_testing();
