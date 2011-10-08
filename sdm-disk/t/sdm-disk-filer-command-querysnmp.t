
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

use Test::More;
use Test::Output;
use Test::Exception;
use Data::Dumper;

use_ok( 'SDM' );

unless ($ENV{SDM_GENOME_INSTITUTE_NETWORKS}) {
    plan skip_all => "Don't assume we can reach SNMP on named hosts for non GI networks";
}

use SDM::Utility::SNMP;
use SDM::Disk::Filer::Command::QuerySnmp;

# Start with a fresh database
use FindBin;
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";

my $t = SDM::Disk::Lib->new();
ok( $t->testinit == 0, "ok: init db");
#ok( $t->testdata == 0, "ok: add data");

sub fileslurp {
    my $filename = shift;
    open(FH,"<$filename") or die "Failed to open $filename: $!";
    my $content = do { local $/; <FH> };
    close(FH);
    return $content;
}

my $gpfsdev = SDM::Disk::Filer->create( name => 'gpfs-dev' );
ok( defined $gpfsdev->id, "created filer ok");
my $gpfs2 = SDM::Disk::Filer->create( name => 'gpfs2' );
ok( defined $gpfs2->id, "created filer ok");

# mimic acquire_volume_data and update_volumes
my $c = SDM::Disk::Filer::Command::QuerySnmp->create( loglevel => "DEBUG", filername => "gpfs-dev", discover_volumes => 0, discover_groups => 0 );
my $d = SDM::SNMP::DiskUsage->create( loglevel => "DEBUG", discover_volumes => 1, hostname => 'linuscs107' );
$d->hosttype('netapp');
# first with discover_volumes = 0 then 1
# netapp and linux host
my $oid = 'dfTable';
my $lines = fileslurp("$top/t/dfTable.txt");
my @content = map { $d->_parse_snmp_line($_) } @{ [ split("\n",$lines) ] };
my $snmp_table = $d->read_snmp_into_table($oid, \@content);
my $table = $d->_convert_to_volume_data( $snmp_table );
$c->_update_volumes( $table, $gpfsdev );
delete $table->{'/vol/x64mswin/'};
$c->_update_volumes( $table, $gpfsdev );

$d->hosttype('linux');
$oid = 'hrStorageTable';
$lines = fileslurp("$top/t/hrStorageTable.txt");
@content = map { $d->_parse_snmp_line($_) } @{ [ split("\n",$lines) ] };
$snmp_table = $d->read_snmp_into_table($oid, \@content);
$table = $d->_convert_to_volume_data( $snmp_table );
$c->_update_volumes( $table, $gpfs2 );

UR::Context->commit();

done_testing();
