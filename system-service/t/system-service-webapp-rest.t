
use strict;
use warnings;
use Test::More;
plan tests => 1;

use above 'System';

my $restapp = require System::Service::WebApp->base_dir . '/Rest.psgi';

ok( $restapp, 'loaded Rest.psgi' );

