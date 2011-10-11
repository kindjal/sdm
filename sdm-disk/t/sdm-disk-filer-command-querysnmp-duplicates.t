
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

use SDM::Utility::SNMP;

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";

my $t = SDM::Disk::Lib->new();
ok( $t->testinit == 0, "ok: init db");

sub fileslurp {
    my $filename = shift;
    open(FH,"<$filename") or die "Failed to open $filename: $!";
    my $content = do { local $/; <FH> };
    close(FH);
    return $content;
}

my $nfs11 = SDM::Disk::Filer->create( name => 'nfs11', type => 'snmp' );
ok( defined $nfs11->id, "created filer nfs11");
my $nfs12 = SDM::Disk::Filer->create( name => 'nfs12', type => 'snmp' );
ok( defined $nfs12->id, "created filer nfs12");
$nfs12->duplicates('nfs11');

# mimic acquire_volume_data and update_volumes
my $c = SDM::Disk::Filer::Command::Query::SnmpDiskUsage->create( loglevel => "DEBUG", filer => $nfs11, discover_volumes => 1, discover_groups => 1, unittest => 1 );
$c->hosttype('netapp');
my $oid = 'dfTable';
my $lines = fileslurp("$top/t/dfTable.txt");
my @content = map { $c->_parse_snmp_line($_) } @{ [ split("\n",$lines) ] };
my $snmp_table = $c->read_snmp_into_table($oid, \@content);
my $table = $c->_convert_to_volume_data( $snmp_table );
$c->_update_volumes( $table, $nfs11 );

UR::Context->commit();

done_testing();
