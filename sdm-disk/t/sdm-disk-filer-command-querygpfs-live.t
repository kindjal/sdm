
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use Sdm;

use Test::More;
use Test::Output;
use Test::Exception;

unless ($ENV{SDM_GENOME_INSTITUTE_NETWORKS}) {
    plan skip_all => "Test only valid on GI networks";
}
plan skip_all => "Test only valid on GI networks";

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";
ok( Sdm::Disk::Lib->testinit == 0, "ok: init db");

# This test requires a real network connection to a lives host.
my $filername = 'gpfs-dev';
my $hostname = 'linuscs107';
my $filer = Sdm::Disk::Filer->create( name => $filername );
my $host = Sdm::Disk::Host->create( hostname => $hostname, master => 1 );
$host->assign( $filer->name );
my @params = ( loglevel => 'DEBUG', filer => $filer, discover_groups => 1, discover_volumes => 1 );
my $c = Sdm::Disk::Filer::Command::Query::GpfsDiskUsage->create( @params );

# Volume data must be updated before GPFS data is updated below.
$c->acquire_volume_data();
$c->delete;

my $v = Sdm::Disk::Volume->get( physical_path => '/vol/aggr0' );
ok( defined $v->id );

done_testing();
