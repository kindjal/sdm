
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use SDM;

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
ok( SDM::Disk::Lib->testinit == 0, "ok: init db");

# This test requires a real network connection to a lives host.
my $filername = 'gpfs-dev';
my $hostname = 'linuscs103';
my $filer = SDM::Disk::Filer->create( name => $filername );
my $host = SDM::Disk::Host->create( hostname => $hostname );
$host->assign($filer->name);

sub fileslurp {
    my $filename = shift;
    return unless (defined $filename);
    open FH, "<", $filename or die "failed to open $filename: $!";
    my $content = do { local $/; <FH> };
    close(FH);
    return $content;
}

my @params = ( loglevel => 'DEBUG', filer => $filer );
my $c = SDM::Disk::Filer::Command::Query::GpfsDiskUsage->create( @params );

# The following mimic SDM::GPFS::DiskUsage->acquire_volume_data
my $vol;
$c->_parse_mmlscluster( fileslurp( "$top/t/mmlscluster.txt" ) );
$vol = $c->_parse_mmlsnsd( fileslurp( "$top/t/mmlsnsd.txt" ) );
$c->_parse_nsd_df( fileslurp( "$top/t/df.txt" ), $vol );
$c->_parse_mmrepquota( fileslurp( "$top/t/mmrepquota.txt" ), $vol );
$c->_parse_disk_groups( fileslurp( "$top/t/disk_groups.txt" ), $vol );

ok( $vol->{'ams1100'}->{'mount_path'} eq '/gscmnt/ams1100' );
ok( $vol->{'ams1100'}->{'physical_path'} eq '/vol/ams1100' );
ok( $vol->{'ams1100'}->{'disk_group'} eq 'INFO_ALIGNMENTS' );
ok( $vol->{'ams1100'}->{'total_kb'} eq '9034530816' );
ok( $vol->{'ams1100'}->{'used_kb'} eq '8598247168' );

@params = ( loglevel => 'DEBUG', filer => $filer, discover_groups => 0, discover_volumes => 0 );
$c = SDM::Disk::Filer::Command::Query::GpfsDiskUsage->create( @params );
$c->_update_volumes( $vol, $filer );
stderr_unlike { UR::Context->commit(); } qr/ERROR/, 'commit runs ok';

@params = ( loglevel => 'DEBUG', filer => $filer, discover_groups => 1, discover_volumes => 1 );
$c = SDM::Disk::Filer::Command::Query::GpfsDiskUsage->create( @params );
$c->_update_volumes( $vol, $filer );
stderr_unlike { UR::Context->commit(); } qr/ERROR/, 'commit runs ok';

my $v = SDM::Disk::Volume->get( physical_path => "/vol/aggr0/gc7001" );
ok( $v->physical_path eq '/vol/aggr0/gc7001', "volume is fileset" );

my $rrd = SDM::Utility::DiskGroupRRD->create( loglevel => 'DEBUG' );
$rrd->run();

$filer->delete();
stderr_unlike { UR::Context->commit(); } qr/ERROR/, 'commit runs ok';

done_testing();
