#! /usr/bin/perl

use Test::More;
use Test::Output;
use FindBin;
use IPC::Cmd;
use File::Basename qw/dirname/;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
    $ENV{SDM_NO_REQUIRE_USER_VERIFY} = 1;
};

my $top = dirname __FILE__;
require "$top/sdm-service-lib.pm";
my $t = SDM::Test::Lib->new();
my $perl = $t->{perl};
my $sdm = $t->{sdm};
# Start with a fresh database
ok( $t->testinit == 0, "ok: init db");

my @files = ('/gscmnt/gc2111/foo (gpfs:/vol/gc2111)','/gscmnt/gc2111/bar (gpfs:/vol/gc2111)','/gscmnt/gc2112/baz (gpfs:/vol/gc2112)');

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
UR::Context->commit();

# -- Now we're prepped, run some commands

# The following create a few entries to build 2 filers the way we know they should look.
stdout_like { $t->runcmd("$perl $sdm service lsof file list --noheaders --filter filename~foo"); } qr/foo/, "file list works";
stdout_like { $t->runcmd("$perl $sdm service lsof file list --noheaders --filter physical_path~gc2112"); } qr/baz/, "filter works";
done_testing();
