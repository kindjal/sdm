
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use Test::More;
use Test::Output;
use Test::Exception;
use Data::Dumper;

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

my $s = Sdm::Asset::Hardware->define_set();
my $v;
eval {
  $v = $s->create_view( perspective => 'table', toolkit => 'json' );
};
warn "first " . Data::Dumper::Dumper $v;
eval {
  $v = $s->create_view( subject_class_name => 'Sdm::Object::Set', perspective => 'table', toolkit => 'json' );
};
die $@ if ($@);
warn "next " . Data::Dumper::Dumper $v;
my $out = $v->_generate_content();
warn "" . Data::Dumper::Dumper $out;
done_testing();
