
use strict;
use warnings;

BEGIN {
    $ENV{SYSTEM_DEPLOYMENT} = "testing";
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

use System;

use Test::More;
use Test::Output;
use Test::Exception;

my $res;
my $params;

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/system-lib.pm";
ok( System::Test::Lib->testinit == 0, "ok: init db");

# Test insufficient creation params
my @params = ();
ok( ! defined System::Disk::Array->create( @params ), "properly fail to create array with empty param" );

# Test creation
@params = ( name => 'nsams2k1' );
$res = System::Disk::Array->create( @params );
ok( $res->id eq 'nsams2k1', "properly created new array");
@params = ( name => 'nsams2k1' );
$res = System::Disk::Array->get( @params );
ok( $res->id eq 'nsams2k1', "properly got new array");

@params = ( name => 'nsams2k4' );
$res = System::Disk::Array->create( @params );
ok( $res->id eq 'nsams2k4', "properly created another new array");

# Test deletion of 1 Array
@params = ( name => 'nsams2k1' );
$res = System::Disk::Array->get( @params );
$res->delete();
isa_ok( $res, 'UR::DeletedRef', "properly delete array" );

# Test update of value
@params = ( name => 'nsams2k4' );
$res = System::Disk::Array->get( @params );
$res->type("AMS");
ok( $res->type eq "AMS", "Type set to AMS");

# Update created and last modified
$res->created( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time()) );
$res->last_modified( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time() - 87000 ) );

# Now test 'delete'
$res = System::Disk::Array->get();
$res->delete();
isa_ok( $res, 'UR::DeletedRef' );

done_testing();
