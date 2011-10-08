
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
    plan skip_all => "Don't assume we can reach SNMP on named hosts for non GI networks";
}

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
if ($top =~ /deploy/) {
    require "$top/t/sdm-disk-lib.pm";
} else {
    require "$top/../sdm-disk/t/sdm-disk-lib.pm";
}
ok( SDM::Disk::Lib->has_gpfs_snmp == 1, "has gpfs");
ok( SDM::Disk::Lib->testinit == 0, "init db");
ok( SDM::Disk::Lib->testdata == 0, "data db");

my $res;
my @res;

@res = SDM::Gpfs::GpfsDiskConfig->get( filername => 'fakefiler' );
ok( ! @res, "fake filer returns undef" );

@res = SDM::Gpfs::GpfsDiskConfig->get( filername => 'gpfs-dev' );
$res = shift @res;

ok( ref $res eq "SDM::Gpfs::GpfsDiskConfig", "object made correctly");
ok( $res->filername eq 'gpfs-dev', "filername set");
ok( ref $res->filer eq 'SDM::Disk::Filer', "filer object related");
#ok( ref $res->volume eq 'SDM::Disk::Volume', "volume object related");

ok( defined $res->filername, "filer attr set" );
#ok( defined $res->volume, "volume attr set");
ok( defined $res->gpfsDiskConfigName, "attr set");
ok( defined $res->gpfsDiskConfigFSName, "attr set");
ok( defined $res->gpfsDiskConfigStgPoolName, "attr set");
ok( defined $res->gpfsDiskMetadata, "attr set");
ok( defined $res->gpfsDiskData, "attr set");

done_testing();
