
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} = "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

use Test::More;
use Test::Output;
use Test::Exception;
use Data::Dumper;

use HTML::TreeBuilder;

use_ok( 'Sdm' );
use_ok( 'Sdm::Disk::Volume::Set::View::Status::Json' );

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";

my $t = Sdm::Disk::Lib->new();
ok( $t->testinit == 0, "ok: init db");
ok( $t->testdata == 0, "ok: add data");

# This is what Rest.psgi does
my @s = Sdm::Disk::Volume->get();
my $vol = $s[0];
$vol->total_kb(145000000);
my $v = $vol->create_view( perspective => 'default', toolkit => 'text' );
my $c = $v->_generate_content();
print $c;

done_testing();
