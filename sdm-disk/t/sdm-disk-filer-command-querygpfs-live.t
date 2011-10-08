
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
my @params = ( loglevel => 'DEBUG', filername => "gpfs-dev", hostname => 'linuscs107', discover_groups => 1 );
my $c = SDM::Disk::Filer::Command::QueryGpfs->create( @params );

# Volume data must be updated before GPFS data is updated below.
$c->execute();
$c->delete;

$c = SDM::Disk::Filer::Command::QueryGpfs->create( @params );
$c->execute();

my $v = SDM::Disk::Volume->get( physical_path => '/vol/aggr0' );
ok( defined $v->id );

done_testing();
