
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use SDM;
use SDM::Utility::GPFS::DiskUsage;
use SDM::Disk::Filer::Command::QueryGpfs;

use Test::More;
use Test::Output;
use Test::Exception;

unless ($ENV{SDM_GENOME_INSTITUTE_NETWORKS}) {
    plan skip_all => "Test only valid on GI networks";
}

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";
ok( SDM::Test::Lib->testinit == 0, "ok: init db");

# This test requires a real network connection to a lives host.
my $host = 'linuscs103';
my $f = SDM::Disk::Filer->create( name => "gpfs" );
my $h = SDM::Disk::Host->create( hostname => $host );
$h->assign($f->name);

my @params = ( loglevel => 'DEBUG', hostname => $host );

sub fileslurp {
    my $filename = shift;
    return unless (defined $filename);
    open FH, "<", $filename or die "failed to open $filename: $!";
    my $content = do { local $/; <FH> };
    close(FH);
    return $content;
}

my $c = SDM::Utility::GPFS::DiskUsage->create( @params );

$c->parse_mmlscluster( fileslurp( "$top/t/mmlscluster.txt" ) );
$h = SDM::Disk::Host->get( hostname => $host );
ok( $h->master == 1, "master host found" );

my $vol = $c->parse_mmlsnsd( fileslurp( "$top/t/mmlsnsd.txt" ) );
$c->parse_nsd_df( fileslurp( "$top/t/df.txt" ), $vol );

$c->parse_mmrepquota( fileslurp( "$top/t/mmrepquota.txt" ), $vol );
my $expected = [
  ['gc7000','FILESET','62210072304','0','214748364800','27967088','none','214324','0','0','138','none','e' ],
  ['gc7001','FILESET','93793940608','0','214748364800','3597672','none','4376582','0','0','574','none','e' ],
];
ok( is_deeply( $vol->{'aggr0'}->{'filesets'}, $expected, "ok: is_deeply"), "ok: mmreqpquota parses");

$c->parse_disk_groups( fileslurp( "$top/t/disk_groups.txt" ), $vol );
$expected = {
    'ams2k4lun00b4' => [
        'linuscs105.gsc.wustl.edu',
        'linuscs106.gsc.wustl.edu',
        'linuscs103.gsc.wustl.edu',
        'linuscs104.gsc.wustl.edu '
        ],
    'mount_path' => '/gscmnt/gc4013',
    'physical_path' => '/vol/gc4013',
    'disk_group' => 'INFO_GENOME_MODELS',
    'total_kb' => '6914310144',
    'ams2k4lun00b3' => [
        'linuscs103.gsc.wustl.edu',
        'linuscs104.gsc.wustl.edu',
        'linuscs105.gsc.wustl.edu',
        'linuscs106.gsc.wustl.edu '
        ],
    'used_kb' => '5184528384',
    'ams2k4lun002f' => [
        'linuscs103.gsc.wustl.edu',
        'linuscs104.gsc.wustl.edu',
        'linuscs105.gsc.wustl.edu',
        'linuscs106.gsc.wustl.edu '
        ]
};
ok( is_deeply( $vol->{'gc4013'}, $expected, "ok: is_deeply"), "ok: mmlsnsd parses");

@params = ( loglevel => 'DEBUG', filername => "gpfs", discover_groups => 1 );

$c = SDM::Disk::Filer::Command::QueryGpfs->create( @params );
# Volume data must be updated before GPFS data is updated below.
$c->update_volumes( $vol, "gpfs" );
UR::Context->commit();

my $v = SDM::Disk::Volume->get( name => "gc7001" );
ok( $v->name eq 'gc7001', "volume is fileset" );

my $rrd = SDM::Utility::DiskGroupRRD->create( loglevel => 'DEBUG' );
$rrd->run();

done_testing();
