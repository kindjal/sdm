
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} = "testing";
};

use Sdm;

use Test::More;
use Test::Output;
use Test::Exception;

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";
ok( Sdm::Disk::Lib->testinit == 0, "ok: init db");

# Test insufficient creation params
my @params = ();

# Create filer to test with
ok( defined Sdm::Disk::Filer->create( name => 'nfs11' ), "created test filer ok");

# Create test group to test with
ok( defined Sdm::Disk::Group->create( name => 'INFO_GENOME_MODELS' ), "created test group ok");
ok( defined Sdm::Disk::Group->create( name => 'INFO_APIPE' ), "created test group ok");

# Test creation
@params = ( filername => 'nfs11', physical_path => '/vol/sata800', disk_group => 'INFO_GENOME_MODELS', total_kb => 20, used_kb => 5 );
my $res = Sdm::Disk::Volume->create( @params );
ok( defined $res, "properly created new volume");

@params = ( filername => 'nfs11', physical_path => '/vol/sata801', disk_group => 'INFO_GENOME_MODELS', total_kb => 10, used_kb => 0 );
$res = Sdm::Disk::Volume->create( @params );
ok( defined $res, "properly created new volume");

@params = ( filername => 'nfs11', physical_path => '/vol/sata802', disk_group => 'INFO_APIPE', total_kb => 30, used_kb => 2 );
$res = Sdm::Disk::Volume->create( @params );
ok( defined $res, "properly created new volume");

@params = ( filername => 'nfs11', physical_path => '/vol/sata803', disk_group => 'INFO_APIPE', total_kb => 5, used_kb => 8 );
$res = Sdm::Disk::Volume->create( @params );
ok( defined $res, "properly created new volume");

my @res = Sdm::Disk::Volume->get( -group_by => ['disk_group'], -order_by => ['disk_group'] );
warn "result of get: " . Data::Dumper::Dumper @res;
__END__
my $item = $res[0];
ok($item->disk_group() eq 'INFO_APIPE', "ok: INFO_APIPE comes first");
ok($item->count() == 2, "ok: 2 members of INFO_APIPE");
ok($item->min('total_kb') == 5, "ok: 5 is min total_kb");
ok($item->max('total_kb') == 30, "ok: 30 is max total_kb");
ok($item->sum('total_kb') == 35, "ok: 35 is sum total_kb");
$item = $res[1];
ok($item->disk_group() eq 'INFO_GENOME_MODELS', "ok: INFO_GENOME_MODELS comes next");
ok($item->count() == 2, "ok: 2 members of INFO_GENOME_MODELS");
ok($item->min('total_kb') == 10, "ok: 10 is min total_kb");
ok($item->max('total_kb') == 20, "ok: 20 is max total_kb");
ok($item->sum('total_kb') == 30, "ok: 30 is sum total_kb");

done_testing();
