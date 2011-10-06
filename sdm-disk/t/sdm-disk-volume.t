
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

my $res;
my $params;

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";
ok( SDM::Disk::Lib->testinit == 0, "ok: init db");

# Test insufficient creation params
my @params = ();
ok( ! defined SDM::Disk::Volume->create( @params ), "properly fail to create volume with empty param" );
@params = ( mount_point => '/gscmnt' );
ok( ! defined SDM::Disk::Volume->create( @params ), "properly fail to create volume with no filer or physical path" );
@params = ( physical_path => '/vol/sata800' );
ok( ! defined SDM::Disk::Volume->create( @params ), "properly fail to create volume with no filer or mount_point" );
@params = ( mount_point => '/gscmnt', filername => 'nfs11' );
ok( ! defined SDM::Disk::Volume->create( @params ), "properly fail to create volume with no physical_path" );

# Create filer to test with
my $nfs11 = SDM::Disk::Filer->create( name => 'nfs11', type => 'polyserve' );
ok( defined $nfs11, "created test filer ok");
my $nfs12 = SDM::Disk::Filer->create( name => 'nfs12', type => 'polyserve' );
ok( defined $nfs12, "created test filer ok");
my $gpfs = SDM::Disk::Filer->create( name => 'gpfs', type => 'gpfs' );
ok( defined $gpfs, "created test filer ok");

ok( my $array = SDM::Disk::Array->create( name => 'nsams2k1' ), "created test array ok");
ok( my $host = SDM::Disk::Host->create( hostname => 'linuscs103' ), "created test host ok");
my $r = $array->assign( "linuscs103" );
isa_ok( $r, "SDM::Disk::HostArrayBridge" );
$r = $host->assign( "nfs11" );
isa_ok( $r, "SDM::Disk::FilerHostBridge" );

# Create test group to test with
ok( defined SDM::Disk::Group->create( name => 'INFO_GENOME_MODELS' ), "created test group ok");

# Test creation
@params = ( filername => 'nfs11', mount_point => '/gscmnt', physical_path => '/vol/sata800', disk_group => 'INFO_GENOME_MODELS', total_kb => 2, used_kb => 1 );
$res = SDM::Disk::Volume->create( @params );
ok( defined $res->id, "properly created new volume");
$res->delete;

# Create via volume
@params = ( mount_point => '/gscmnt', physical_path => '/vol/sata800', disk_group => 'INFO_GENOME_MODELS', total_kb => 2, used_kb => 1 );
$res = $nfs11->create_volume( @params );
ok( defined $res->id, "properly created new volume");

# Create volume directly
@params = ( mount_point => '/gscmnt', physical_path => '/vol/sata800', disk_group => 'INFO_GENOME_MODELS', total_kb => 2, used_kb => 1 );
$res = SDM::Disk::Volume->get( @params );
ok( defined $res->id, "properly got new volume");

# Test creation of new mount of same Volume mount_path
@params = ( filername => 'nfs12', mount_point => '/gscmnt', physical_path => '/vol/sata800', disk_group => 'INFO_GENOME_MODELS', total_kb => 2, used_kb => 1, duplicates => $res->id );
$res = SDM::Disk::Volume->get_or_create( @params );
UR::Context->commit();
ok( defined $res->id, "properly created duplicate volume");
__END__

@params = ( filername => 'nfs12', mount_point => '/gscmnt', physical_path => '/vol/sata800', duplicates => $res->id );
$res = SDM::Disk::Volume->get_or_create( @params );
UR::Context->commit();
ok( defined $res->id, "properly created duplicate volume");

# Test update of value
@params = ( physical_path => '/vol/sata800' );
$res = SDM::Disk::Volume->get( @params );
$res->total_kb(1000);
ok( $res->total_kb == 1000, "total_kb set to 1000");

# Update last modified to age the volume
$res->last_modified( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time()) );
ok( $res->is_current(86400) == 0, "volume is current" );
$res->last_modified( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time() - 87000 ) );
ok( $res->is_current(86400) == 1, "volume is aged");

# Test validate and purge for aging volumes
stderr_like { $res->validate(); } qr|Aging volume: /gscmnt/sata800|, "validate runs ok";
stderr_like { $res->purge(); } qr|Purging aging volume: /gscmnt/sata800|, "validate runs ok";

# Now test 'delete'
@params = ( mount_point => '/gscmnt', filername => 'nfs11', physical_path => '/vol/sata800' );
$res = SDM::Disk::Volume->create( @params );
$res = SDM::Disk::Volume->get( @params );
$res->delete();
isa_ok( $res, 'UR::DeletedRef' );

done_testing();

