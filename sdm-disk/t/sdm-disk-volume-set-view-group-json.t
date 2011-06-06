
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
use_ok( 'SDM::Disk::Volume::Set::View::Group::Json' );

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-lib.pm";

my $t = SDM::Test::Lib->new();
ok( $t->testinit == 0, "ok: init db");
ok( $t->testdata == 0, "ok: add data");

# This is what Rest.psgi does
my $s = SDM::Disk::Volume->define_set();
my $v = $s->create_view( perspective => 'group', toolkit => 'json' );
my $got = $v->_generate_content();

# This must match the data used in SDM::Test::Lib->testdata
my $expected = {
   "aaData" => [
      [
         "unknown",
         100,
         90,
         90
      ],
      [
         "INFO_APIPE",
         100,
         90,
         90
      ],
      [
         "SYSTEMS",
         100,
         90,
         90
      ],
      [
         "SYSTEMS_DEVELOPMENT",
         300,
         230,
         76.6666666666667
      ]
   ],
   "iTotalRecords" => 4,
   "iTotalDisplayRecords" => 4,
   "sEcho" => 1
};
use JSON;
my $json = JSON->new->ascii->pretty->allow_nonref;
$expected = $json->encode($expected);

ok( is_deeply( $got, $expected, "ok: is_deeply" ), "ok: json match");

done_testing();
