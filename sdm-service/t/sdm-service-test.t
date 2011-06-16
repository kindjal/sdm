
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
use_ok( 'SDM::Disk::Filer::Set::View::Status::Json' );

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-service-lib.pm";

my $t = SDM::Test::Lib->new();
ok( $t->testinit == 0, "ok: init db");
ok( $t->testdata == 0, "ok: add data");

done_testing();
