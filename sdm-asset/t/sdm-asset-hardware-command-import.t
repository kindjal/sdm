
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use Test::More;
use Test::Output;
use Test::Exception;

use_ok( 'SDM' );

# Start with an empty database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-asset-lib.pm";

my $t = SDM::Test::Lib->new();
ok( $t->testinit == 0, "ok: init db");

# We need hosts to map to filers.
my $csvfile = "$top/t/asset-inventory.csv";
my $c = SDM::Asset::Hardware::Command::Import->create( loglevel => "DEBUG", csv => $csvfile, flush => 1, commit => 1 );
lives_ok { $c->execute(); } "import run lived";

my @o = SDM::Asset::Hardware->get();
my $obj = pop @o;
ok($obj->location eq 'The astral plane');
ok($obj->serial eq 'xa1234yz');
ok($obj->model eq 'G3730');
ok($obj->comments eq 'This is a comment');
ok($obj->description eq 'This is a sample piece of hardware');
ok($obj->manufacturer eq 'Dell');

done_testing();
