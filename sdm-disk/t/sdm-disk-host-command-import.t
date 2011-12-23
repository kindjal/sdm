
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} = "testing";
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
my $c = Sdm::Disk::Array::Command::Import->create( loglevel => "DEBUG", csv => $csvfile, flush => 1, commit => 1 );
lives_ok { $c->execute(); } "host run lived";

$csvfile = "$top/t/host-inventory.csv";
$c = Sdm::Disk::Host::Command::Import->create( loglevel => "DEBUG", csv => $csvfile, commit => 1, flush => 1 );
lives_ok { $c->execute(); } "run lived";

my $o = Sdm::Disk::Host->get( hostname => 'linuscs107' );
ok( $o->hostname eq "linuscs107", "hostname set" );
ok( $o->model eq "poweredge R710", "model set" );
ok( $o->manufacturer eq "Dell", "mfr set" );
ok( $o->os eq "RHEL 5.5", "os set" );
ok( $o->location eq "222 ns rack 2.11", "location set" );

# Try redundantly
$c = Sdm::Disk::Host::Command::Import->create( loglevel => "DEBUG", csv => $csvfile, commit => 1 );
lives_ok { $c->execute(); } "rerun lived";

done_testing();
