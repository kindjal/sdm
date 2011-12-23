
use strict;
use warnings;

BEGIN {
    $ENV{DEPLOYMENT} = "testing";
};

# the order is important
use Test::More;
use Sdm::Dancer::Handlers;
use Dancer::Test;
use HTML::TreeBuilder;

# reset appdir and paths to sdm-web paths
my $appdir = Sdm->base_dir;
Dancer::set appdir => $appdir;
Dancer::set public => $appdir . "/public";
Dancer::set views => $appdir . "/views";

route_exists [GET => '/'], 'a route handler is defined for /';
response_status_is ['GET' => '/'], 200, 'response status is 200 for /';

my $response = dancer_response GET => '/';
my $tree = HTML::TreeBuilder->new_from_content($response->content) or die "$!";

my $title = $tree->look_down( '_tag', 'title' );
ok($title->as_text eq "Success", "ok: title match");

my $item = $tree->look_down( sub { $_[0]->tag() eq 'div' and $_[0]->attr('id') and $_[0]->attr('class') and ( $_[0]->attr('id') =~ /status/ and $_[0]->attr('class') =~ /success/ ); } );
ok($item->as_text =~ /SDM is ready to serve/, "ok: SDM ready");

done_testing();
