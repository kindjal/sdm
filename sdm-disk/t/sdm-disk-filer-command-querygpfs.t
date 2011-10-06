
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use SDM;
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
ok( SDM::Disk::Lib->testinit == 0, "ok: init db");

# This test requires a real network connection to a lives host.
my $host = 'linuscs103';
my $f = SDM::Disk::Filer->create( name => "gpfs-dev", type => "gpfs" );
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

my $c = SDM::GPFS::DiskUsage->create( @params );
# The following mimic SDM::GPFS::DiskUsage->acquire_volume_data
my $vol;
$c->_parse_mmlscluster( fileslurp( "$top/t/mmlscluster.txt" ) );
$vol = $c->_parse_mmlsnsd( fileslurp( "$top/t/mmlsnsd.txt" ) );
$c->_parse_nsd_df( fileslurp( "$top/t/df.txt" ), $vol );
$c->_parse_mmrepquota( fileslurp( "$top/t/mmrepquota.txt" ), $vol );
$c->_parse_disk_groups( fileslurp( "$top/t/disk_groups.txt" ), $vol );

$h = SDM::Disk::Host->get( hostname => $host );
ok( $h->master == 1, "master host found" );

ok( $vol->{'ams1100'}->{'mount_path'} eq '/gscmnt/ams1100' );
ok( $vol->{'ams1100'}->{'physical_path'} eq '/vol/ams1100' );
ok( $vol->{'ams1100'}->{'disk_group'} eq 'INFO_ALIGNMENTS' );
ok( $vol->{'ams1100'}->{'total_kb'} eq '9034530816' );
ok( $vol->{'ams1100'}->{'used_kb'} eq '8598247168' );

@params = ( loglevel => 'DEBUG', filername => "gpfs", discover_groups => 1 );

$c = SDM::Disk::Filer::Command::QueryGpfs->create( @params );

# Volume data must be updated before GPFS data is updated below.
$c->_update_volumes( $vol, "gpfs-dev" );
UR::Context->commit();

my $v = SDM::Disk::Volume->get( physical_path => "/vol/aggr0/gc7001" );
ok( $v->physical_path eq '/vol/aggr0/gc7001', "volume is fileset" );

my $rrd = SDM::Utility::DiskGroupRRD->create( loglevel => 'DEBUG' );
$rrd->run();

done_testing();
