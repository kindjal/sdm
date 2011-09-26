
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use Test::More;
use Test::Output;
use Test::Exception;

use_ok( 'SDM' );

unless ($ENV{SDM_GENOME_INSTITUTE_NETWORKS}) {
    plan skip_all => "Don't assume we can reach SNMP on named hosts for non GI networks";
}

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";

my $t = SDM::Test::Lib->new();
ok( $t->testinit == 0, "ok: init db");
ok( $t->testdata == 0, "ok: add data");

my $c = SDM::Utility::GPFS::DiskUsage->create( loglevel => "DEBUG" );

open(FH,"<$top/t/mmlscluster.txt") or "die failed to open mmlscluster.txt";
my $content = do { local $/; <FH> };
close(FH);
$c->parse_mmlscluster($content);

#stderr_like { $c->execute(); } qr/DiskUsage no volume found for gpfs-dev/, "skipped unknown volume ok";
#
#$c = SDM::Disk::Filer::Command::QueryGpfs->create( loglevel => "DEBUG", filername => "gpfs-dev", discover_volumes => 1 );
#lives_ok { $c->execute(); } "run lived";
#my @v = SDM::Disk::Volume->get( filername => "gpfs-dev" );
#my $v = shift @v;
#ok($v->filername eq 'gpfs-dev', "filername set");
#ok(defined $v->name, "volume name set");
#ok(defined $v->used_kb, "used_kb set");

done_testing();
