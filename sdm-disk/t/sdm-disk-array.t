
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} = "testing";
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
ok( ! defined Sdm::Disk::Array->create( @params ), "properly fail to create array with empty param" );

# Test creation
@params = ( name => 'nsams2k1' );
$res = Sdm::Disk::Array->create( @params );
ok( $res->id eq 'nsams2k1', "properly created new array");
@params = ( name => 'nsams2k1' );
$res = Sdm::Disk::Array->get( @params );
ok( $res->id eq 'nsams2k1', "properly got new array");

@params = ( name => 'nsams2k4' );
$res = Sdm::Disk::Array->create( @params );
ok( $res->id eq 'nsams2k4', "properly created another new array");

# Test deletion of 1 Array
@params = ( name => 'nsams2k1' );
$res = Sdm::Disk::Array->get( @params );
$res->delete();
isa_ok( $res, 'UR::DeletedRef', "properly delete array" );

# Test update of value
@params = ( name => 'nsams2k4' );
$res = Sdm::Disk::Array->get( @params );
ok( $res->name eq "nsams2k4", "name ok");

# Update created and last modified
$res->created( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time()) );
$res->last_modified( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time() - 87000 ) );

# Test assign
my $host = Sdm::Disk::Host->create( hostname => "linuscs103" );
my $hrb = $res->assign( $host->hostname );
isa_ok( $hrb, 'Sdm::Disk::HostArrayBridge' );

# Now test 'delete'
$res = Sdm::Disk::Array->get();
$res->delete();
isa_ok( $res, 'UR::DeletedRef' );

done_testing();
