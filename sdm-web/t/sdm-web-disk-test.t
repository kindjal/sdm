
use strict;
use warnings;

BEGIN{
    $ENV{SDM_DEPLOYMENT} = "testing";
};

use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;

use Test::More;

unless ($top =~ /\/deploy$/) {
    # We need access to our full compliment of sdm sub modules
    # so we can create sample data and examine the web views.
    plan skip_all => "only run these unit tests from a ./deploy directory";
}

# the order is important
use Sdm;
use Sdm::Dancer::Handlers;
use Dancer::Test;
use HTML::TreeBuilder;

# reset appdir and paths to sdm-web paths based in ./deploy/lib
my $appdir = Sdm->base_dir;
Dancer::set appdir => $appdir;
Dancer::set public => $appdir . "/public";
Dancer::set views => $appdir . "/views";

# Start with a fresh database
require "$top/t/sdm-web-lib.pm";
ok( Sdm::Web::Lib->testinit == 0, "init db");
ok( Sdm::Web::Lib->testdata == 0, "test data");

my $response = dancer_response GET => '/';
my $tree = HTML::TreeBuilder->new_from_content($response->content) or die "$!";
my $item = $tree->look_down( sub { $_[0]->tag() eq 'div' and $_[0]->attr('id') and $_[0]->attr('class') and ( $_[0]->attr('id') =~ /status/ and $_[0]->attr('class') =~ /success/ ); } );
ok($item->as_text =~ /SDM is ready to serve/, "ok: SDM ready");

$response = dancer_response GET => '/rrd.html?INFO_APIPE';
ok($response->{status} == 200, "page returns");

$response = dancer_response GET => '/diskstatus.html';
ok($response->{status} == 200, "returns 200");
my $fh = $response->content;
my $content = do { local $/; <$fh> };
$tree = HTML::TreeBuilder->new_from_content($content) or die "$!";
my @items = $tree->look_down( sub { $_[0]->tag() eq 'table' and $_[0]->attr('id') and ( $_[0]->attr('id') =~ /table/ ); } );
foreach my $item (@items) {
    ok($item->as_HTML =~ /<table/, "found table");
}

$response = dancer_response GET => '/view/sdm/disk/filer/table.html';
ok($response->{status} == 200);
$tree = HTML::TreeBuilder->new_from_content($response->content) or die "$!";
@items = $tree->look_down( sub { $_[0]->tag() eq 'table' and $_[0]->attr('id') and ( $_[0]->attr('id') =~ /table/ ); } );
foreach my $item (@items) {
    ok($item->as_HTML =~ /<table/, "found table");
}

$response = dancer_response GET => '/view/sdm/disk/host/table.html';
ok($response->{status} == 200);
$tree = HTML::TreeBuilder->new_from_content($response->content) or die "$!";
@items = $tree->look_down( sub { $_[0]->tag() eq 'table' and $_[0]->attr('id') and ( $_[0]->attr('id') =~ /table/ ); } );
foreach my $item (@items) {
    ok($item->as_HTML =~ /<table/, "found table");
}

$response = dancer_response GET => '/view/sdm/disk/array/table.html';
ok($response->{status} == 200);
$tree = HTML::TreeBuilder->new_from_content($response->content) or die "$!";
@items = $tree->look_down( sub { $_[0]->tag() eq 'table' and $_[0]->attr('id') and ( $_[0]->attr('id') =~ /table/ ); } );
foreach my $item (@items) {
    ok($item->as_HTML =~ /<table/, "found table");
}

$response = dancer_response GET => '/view/sdm/disk/volume/table.html';
ok($response->{status} == 200);
$tree = HTML::TreeBuilder->new_from_content($response->content) or die "$!";
@items = $tree->look_down( sub { $_[0]->tag() eq 'table' and $_[0]->attr('id') and ( $_[0]->attr('id') =~ /table/ ); } );
foreach my $item (@items) {
    ok($item->as_HTML =~ /<table/, "found table");
}

$response = dancer_response GET => '/view/sdm/disk/fileset/table.html';
ok($response->{status} == 200);
$tree = HTML::TreeBuilder->new_from_content($response->content) or die "$!";
@items = $tree->look_down( sub { $_[0]->tag() eq 'table' and $_[0]->attr('id') and ( $_[0]->attr('id') =~ /table/ ); } );
foreach my $item (@items) {
    ok($item->as_HTML =~ /<table/, "found table");
}

#$response = dancer_response GET => '/view/sdm/disk/assignment/table.html';
#ok($response->{status} == 200);
#$tree = HTML::TreeBuilder->new_from_content($response->content) or die "$!";
#@items = $tree->look_down( sub { $_[0]->tag() eq 'table' and $_[0]->attr('id') and ( $_[0]->attr('id') =~ /table/ ); } );
#foreach my $item (@items) {
#    ok($item->as_HTML =~ /<table/, "found table");
#}

$response = dancer_response GET => '/view/sdm/disk/group/table.html';
ok($response->{status} == 200);
$tree = HTML::TreeBuilder->new_from_content($response->content) or die "$!";
@items = $tree->look_down( sub { $_[0]->tag() eq 'table' and $_[0]->attr('id') and ( $_[0]->attr('id') =~ /table/ ); } );
foreach my $item (@items) {
    ok($item->as_HTML =~ /<table/, "found table");
}

done_testing();
