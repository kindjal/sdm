
use strict;
use warnings;

BEGIN {
    $ENV{SYSTEM_DEPLOYMENT} ||= "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
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

# Create filer to test with
ok( defined System::Disk::Filer->create( name => 'nfs11' ), "created test filer ok");

# Create test group to test with
ok( defined System::Disk::Group->create( name => 'INFO_GENOME_MODELS' ), "created test group ok");
ok( defined System::Disk::Group->create( name => 'INFO_APIPE' ), "created test group ok");

# Test creation
@params = ( filername => 'nfs11', mount_path => '/gscmnt/sata800', physical_path => '/vol/sata800', disk_group => 'INFO_GENOME_MODELS', total_kb => 20, used_kb => 5 );
$res = System::Disk::Volume->create( @params );
ok( defined $res->id, "properly created new volume");

@params = ( filername => 'nfs11', mount_path => '/gscmnt/sata801', physical_path => '/vol/sata801', disk_group => 'INFO_GENOME_MODELS', total_kb => 10, used_kb => 0 );
$res = System::Disk::Volume->create( @params );
ok( defined $res->id, "properly created new volume");

@params = ( filername => 'nfs11', mount_path => '/gscmnt/sata802', physical_path => '/vol/sata802', disk_group => 'INFO_APIPE', total_kb => 30, used_kb => 2 );
$res = System::Disk::Volume->create( @params );
ok( defined $res->id, "properly created new volume");

@params = ( filername => 'nfs11', mount_path => '/gscmnt/sata803', physical_path => '/vol/sata803', disk_group => 'INFO_APIPE', total_kb => 5, used_kb => 8 );
$res = System::Disk::Volume->create( @params );
ok( defined $res->id, "properly created new volume");

my @res = System::Disk::Volume->get( -order_by => ['-total_kb'] );
print Data::Dumper::Dumper @res;

done_testing();

