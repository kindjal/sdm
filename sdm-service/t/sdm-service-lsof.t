
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
$r->delete;

my @files = ('foo');
$params = {
  hostname => "vm73.gsc.wustl.edu",
  pid      => 12344,
  uid      => 500,
  username => 'luser',
  command  => 'perl',
  name     => \@files,
  nfsd     => '192.168.56.100',
};
$r = SDM::Service::Lsof::Process->create( $params );
ok( defined $r, "create ok");
ok( UR::Context->commit(), "commit ok" );
$r->delete;
ok( UR::Context->commit(), "commit ok" );

@files = ('foo','bar','baz');

$params = {
  hostname => "vm75.gsc.wustl.edu",
  pid      => 12345,
  uid      => 500,
  username => 'luser',
  command  => 'perl',
  nfsd     => '192.168.56.101',
  name     => \@files,
};
$r = SDM::Service::Lsof::Process->create( $params );
ok( defined $r, "create ok");

$params = {
  hostname => "vm76.gsc.wustl.edu",
  pid      => 12346,
  uid      => 501,
  username => 'luser',
  command  => 'perl',
  name     => \@files,
};
$r = SDM::Service::Lsof::Process->create( $params );
my @f = $r->files;

ok( scalar @f == 3, "file list ok");
ok( defined $r, "create ok");

my @files2 = ('bing','boff');
$params = {
  hostname => "vm76.gsc.wustl.edu",
  pid      => 12347,
  pgid     => 12346,
  uid      => 501,
  username => 'luser',
  command  => 'perl',
  name     => \@files2,
};
$r = SDM::Service::Lsof::Process->create( $params );
ok( defined $r, "create ok");
ok( UR::Context->commit(), "commit ok" );

# This should get what we just created.
my $s = SDM::Service::Lsof::Process->get_or_create( $params );
ok( is_deeply( $r, $s, "is_deeply" ), "get_or_create ok" );

my @p = SDM::Service::Lsof::Process->get( hostname => "vm76.gsc.wustl.edu" );
@f = SDM::Service::Lsof::File->get( hostname => "vm76.gsc.wustl.edu" );
@f = map { $_->filename } @f;

my @expected = (@files,@files2);
ok( is_deeply( [ sort @expected ], [ sort @f ], "is_deeply" ), "files match" );

# Deleting pids should autoremove files
foreach my $pid (@p) {
    $pid->delete;
}
UR::Context->commit();

# This should show only files from the remaning pid
@f = SDM::Service::Lsof::File->get();
@f = map { $_->filename } @f;
ok( is_deeply( [ sort @files ], [ sort @f ], "is_deeply" ), "files match" );

foreach my $pid ( SDM::Service::Lsof::Process->get() ) {
    $pid->delete;
}
UR::Context->commit();

done_testing();
