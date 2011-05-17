
use strict;
use warnings;
use Test::More;
plan tests => 1;

use above 'SDM';

my $restapp = require SDM::Service::WebApp->base_dir . '/Rest.psgi';

ok( $restapp, 'loaded Rest.psgi' );

