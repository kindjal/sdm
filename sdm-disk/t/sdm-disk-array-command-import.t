
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

use_ok( 'Sdm' );

# Start with an empty database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";

my $t = Sdm::Disk::Lib->new();
ok( $t->testinit == 0, "ok: init db");

my $csvfile = "$top/t/array-inventory.csv";
my $c = Sdm::Disk::Array::Command::Import->create( loglevel => "DEBUG", csv => $csvfile );
lives_ok { $c->execute(); } "run lived";

done_testing();
