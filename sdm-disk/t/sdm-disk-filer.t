
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} = 'testing';
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
}

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
my $filer = Sdm::Disk::Filer->create( @params );
ok( ! defined Sdm::Disk::Filer->create( @params ), "properly fail to create filer with empty param" );

# Test creation
@params = ( name => 'nfs11' );
$res = Sdm::Disk::Filer->create( @params );
ok( $res->id eq 'nfs11', "properly created new filer nfs11");
@params = ( name => 'nfs11' );
$res = Sdm::Disk::Filer->get( @params );
ok( $res->id eq 'nfs11', "properly got new filer nfs11");

@params = ( name => 'nfs12' );
$res = Sdm::Disk::Filer->create( @params );
ok( $res->id eq 'nfs12', "properly created another new filer nfs12");

# Test deletion of 1 Filer
@params = ( name => 'nfs11' );
$res = Sdm::Disk::Filer->get( @params );
$res->delete();
isa_ok( $res, 'UR::DeletedRef', "properly delete filer nfs11" );

# Test update of value
@params = ( name => 'nfs12' );
$res = Sdm::Disk::Filer->get( @params );
$res->status(1);
ok( $res->status == 1, "status set to 1");

# Update last modified to age the filer
$res->last_modified( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time()) );
ok( $res->is_current(86400) == 0, "filer is current" );
$res->last_modified( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time() - 87000 ) );
ok( $res->is_current(86400) == 1, "filer is aged");

# Now test 'delete'
$res = Sdm::Disk::Filer->get( name => 'nfs12' );
$res->delete();
isa_ok( $res, 'UR::DeletedRef' );

UR::Context->commit();
done_testing();
