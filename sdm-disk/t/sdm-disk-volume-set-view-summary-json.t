
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

use Test::More;
use Test::Output;
use Test::Exception;
use Data::Dumper;

use HTML::TreeBuilder;

use_ok( 'SDM' );
use_ok( 'SDM::Disk::Volume::Set::View::Summary::Json' );

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";

my $t = SDM::Disk::Lib->new();
ok( $t->testinit == 0, "ok: init db");
ok( $t->testdata == 0, "ok: add data");

my @s = SDM::Disk::Volume->define_set();
my $v = $s[0]->create_view( perspective => 'summary', toolkit => 'json' );
my $json = $v->_jsobj();
print Data::Dumper::Dumper $json;

# This must match the data used in SDM::Disk::Lib->testdata
my $expected = {
  'total_kb' => 700,
  'last_modified' => '0000:00:00:00:00:00',
  'used_kb' => 550,
  'capacity' => '78.5714285714286'
};

ok( is_deeply( $json, $expected, "ok: is_deeply" ), "ok: json match");

done_testing();
