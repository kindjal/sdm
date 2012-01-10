
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use Test::More;
use Test::Output;
use Test::Exception;

use_ok( 'Sdm' );

# Start with an empty database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-asset-lib.pm";

my $t = Sdm::Test::Lib->new();
ok( $t->testinit == 0, "ok: init db");

# We need hosts to map to filers.
my $csvfile = "$top/t/hardware-inventory.csv";
my $c = Sdm::Asset::Hardware::Command::Import->create( loglevel => "DEBUG", csv => $csvfile, flush => 1, commit => 1 );
lives_ok { $c->execute(); } "import run lived";

my @o = Sdm::Asset::Hardware->get( tag => 'AB1CD21' );
my $obj = pop @o;
ok($obj->{tag} eq 'AB1CD21');
ok($obj->{location} eq 'here');
ok($obj->{model} eq 'model foo');
ok($obj->{hostname} eq 'testhost.gsc.wustl.edu');
ok($obj->{comments} eq 'this is a test');
done_testing();
