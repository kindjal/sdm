
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use Test::More;
use Test::Output;
use Test::Exception;

use Test::XML::Simple;

use_ok( 'Sdm' );

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";

my $t = Sdm::Disk::Lib->new();
ok( $t->testinit == 0, "ok: init db");
ok( $t->testdata == 0, "ok: add data");

# This is what Rest.psgi does
my $s = Sdm::Disk::Volume->define_set();
my $v = $s->create_view( perspective => 'table', toolkit => 'xml' );
my $xml = $v->_generate_content();

xml_valid $xml, 'valid xml';
xml_is $xml, '/object/aspect[@name="rule_display"]/value', 'UR::BoolExpr=(Sdm::Disk::Volume:)', "aspect match";
xml_like $xml, '/object/aspect[@name="members"]/object[1]/aspect[@name="mount_path"]/value', '/gscmnt/gc', "aspect match";

done_testing();
