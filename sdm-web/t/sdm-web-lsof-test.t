
use strict;
use warnings;

BEGIN{
    $ENV{SDM_DEPLOYMENT} = "testing";
};

use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;

use Test::More;

plan skip_all => "this test doesn't work yet";

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

# This doesn't work.
my $response = dancer_response POST => '/service/lsof', {files => [{name => 'lsofc', filename => "$top/t/lsofcpost.txt"}]};
warn "r " . Data::Dumper::Dumper $response->content;

done_testing();
