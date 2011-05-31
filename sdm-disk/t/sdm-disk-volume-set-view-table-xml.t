
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

use Test::XML::Simple;

use_ok( 'SDM' );

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
my $v = $s->create_view( perspective => 'table', toolkit => 'xml' );
my $xml = $v->_generate_content();

xml_is $xml, '/object/aspect[@name="rule_display"]/value', 'UR::BoolExpr=(SDM::Disk::Volume:)', "aspect match";
xml_is $xml, '/object/aspect[@name="members"]/object/aspect[@name="mount_path"]/value', '/gscmnt/gc2111', "aspect match";

done_testing();