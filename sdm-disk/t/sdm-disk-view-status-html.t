
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

use_ok( 'Sdm' );
use_ok( 'Sdm::View::Diskstatus::Html' );

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";

ok( Sdm::Disk::Lib->testinit == 0, "ok: init db");

my $o = Sdm::View::Diskstatus::Html->create();
my $page = $o->_generate_content();

my $tree = HTML::TreeBuilder->new_from_content($page) or die "$!";
my $title = $tree->look_down( '_tag', 'title' );
ok($title->as_text eq "Disk Usage Information", "ok: title");

done_testing();
