
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
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

# We need hosts to map to filers.
my $csvfile = "$top/t/array-inventory.csv";
my $c = Sdm::Disk::Array::Command::Import->create( loglevel => "DEBUG", csv => $csvfile, flush => 1, commit => 1 );
lives_ok { $c->execute(); } "host run lived";

$csvfile = "$top/t/host-inventory.csv";
$c = Sdm::Disk::Host::Command::Import->create( loglevel => "DEBUG", csv => $csvfile, flush => 1, commit => 1 );
lives_ok { $c->execute(); } "host run lived";

# Now filers
$csvfile = "$top/t/filer-inventory.csv";
$c = Sdm::Disk::Filer::Command::Import->create( loglevel => "DEBUG", csv => $csvfile, flush => 1, commit => 1 );
lives_ok { $c->execute(); } "filer run lived";

my $o = Sdm::Disk::Filer->get( name => "gpfs" );
my @expected = ( "linuscs103","linuscs104","linuscs105","linuscs106" );
my @found = map { $_->hostname } $o->host;
ok( is_deeply( \@expected, \@found, "is_deeply"), "gpfs host list matches" );

done_testing();
