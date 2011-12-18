
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use Test::More;
use Test::Output;
use Test::Exception;
use Data::Dumper;
$Data::Dumper::Indent = 1;

use_ok( 'Sdm' );

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
my $base = "$top/lib/Sdm";
require "$top/t/sdm-service-lib.pm";

my $t = Sdm::Test::Lib->new();
unlink "$base/DataSource/Automount.sqlite3";
unlink "$base/DataSource/Automount.sqlite3-dump";
print "make new sqlite3 DB\n";

my $dbpath = "./foo.sqlite3";

my $c = Sdm::Service::Automount::Command::Export->create( loglevel => "DEBUG", filename => $dbpath );

$t->runcmd("/usr/bin/sqlite3 $dbpath < $base/DataSource/Automount.sqlite3.schema");
$t->runcmd("/usr/bin/sqlite3 $dbpath .dump > $dbpath-dump");

$c->execute;
UR::Context->commit();

done_testing();
