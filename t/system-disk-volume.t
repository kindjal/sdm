
use strict;
use warnings;

use above "System";

use Test::More;
use Test::Exception;

my $res;
my $params;

# Start with a fresh database
system('bash ./t/00-disk-prep-test-database.sh');
ok($? >> 8 == 0, "prep test db ok");

# Volume unit tests:
#   is_current
#   purge
#   validate_volumes

# Test insufficient creation params
my @params = ();
ok( ! defined System::Disk::Volume->create( @params ), "properly fail to create volume with empty param" );
@params = ( mount_path => '/gscmnt/sata800' );
ok( ! defined System::Disk::Volume->create( @params ), "properly fail to create volume with no filer or physical path" );
@params = ( physical_path => '/vol/sata800' );
ok( ! defined System::Disk::Volume->create( @params ), "properly fail to create volume with no filer or mount path" );
@params = ( mount_path => '/gscmnt/sata800', physical_path => '/vol/sata800' );
ok( ! defined System::Disk::Volume->create( @params ), "properly fail to create volume with no filer name" );
@params = ( mount_path => '/gscmnt/sata800', filername => 'nfs11' );
ok( ! defined System::Disk::Volume->create( @params ), "properly fail to create volume with no physical_path" );
@params = ( physical_path => '/vol/sata800', filername => 'nfs11' );
ok( ! defined System::Disk::Volume->create( @params ), "properly fail to create volume with no mount_path" );
@params = ( filername => 'nfs11' );
ok( ! defined System::Disk::Volume->create( @params ), "properly fail to create volume with no physical or mount path" );

# Test creation
@params = ( filername => 'nfs11', mount_path => '/gscmnt/sata800', physical_path => '/vol/sata800' );
$res = System::Disk::Volume->create( @params );
ok( $res->id == 1, "properly created new volume");
@params = ( filername => 'nfs11', mount_path => '/gscmnt/sata800', physical_path => '/vol/sata800' );
$res = System::Disk::Volume->get( @params );
ok( $res->id == 1, "properly got new volume");

# Test creation of new mount of same Volume mount_path
@params = ( filername => 'nfs12', mount_path => '/gscmnt/sata800', physical_path => '/vol/sata800' );
$res = System::Disk::Volume->get_or_create( @params );
eq_array( $res->filername, [ 'nfs11', 'nfs12' ] );

@params = ( filername => 'nfs13', mount_path => '/gscmnt/sata800', physical_path => '/vol/sata800' );
$res = System::Disk::Volume->get_or_create( @params );
eq_array( $res->filername, [ 'nfs11', 'nfs12', 'nfs13' ] );

# Test deletion of 1 of many Mounts of this Volume
$res = System::Disk::Volume->get( @params );
$res->delete( @params );
ok( $res->id == 1, "properly have one of two mounts left" );

# Test update of value
@params = ( filername => 'nfs11', mount_path => '/gscmnt/sata800', physical_path => '/vol/sata800' );
$res = System::Disk::Volume->get( @params );
$res->total_kb(1000);
ok( $res->total_kb == 1000, "total_kb set to 1000");


# Update last modified to age the volume
$res->last_modified( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time()) );
ok( $res->is_current(86400) == 0, "volume is current" );
$res->last_modified( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time() - 87000 ) );
ok( $res->is_current(86400) == 1, "volume is aged");

# Test validate and purge for aging volumes
lives_ok { $res = System::Disk::Volume->validate_volumes(); } "validate runs ok";
lives_ok { $res = System::Disk::Volume->purge(); } "purge runs ok";

# Now test 'delete'
@params = ( filername => 'nfs11', mount_path => '/gscmnt/sata800', physical_path => '/vol/sata800' );
$res = System::Disk::Volume->create( @params );
$res = System::Disk::Volume->get();
$res->delete();
isa_ok( $res, 'UR::DeletedRef' );

done_testing();
