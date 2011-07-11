
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

use_ok( 'SDM' );

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-service-lib.pm";

my $t = SDM::Test::Lib->new();
ok( $t->testinit == 0, "ok: init db");

my $params = { hostname => "vm75.gsc.wustl.edu", pid => 1 };
my $r = SDM::Service::Lsof::Process->create( $params );
ok( UR::Context->commit(), "basic commit ok" );

$params = {
  hostname => "vm73.gsc.wustl.edu",
  pid      => 12344,
  uid      => 500,
  username => 'luser',
  command  => 'perl',
  last_modified => Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()),
};
$r = SDM::Service::Lsof::Process->create( $params );
ok( defined $r, "create ok");
ok( UR::Context->commit(), "commit ok" );

sleep 3;
$r->command( 'python' );
$r->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );

my $c = SDM::Service::Lsof::Process::Command::Purge->create( loglevel => "DEBUG" );
$c->age(2);
my $res = $c->execute();
ok( $res == 1, "purged 1 item");
done_testing();
