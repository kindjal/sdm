
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use SDM;
use SDM::Utility::SNMP::DiskUsage;

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
my $host = 'linuscs107';

my @params = ( command => 'snmpwalk', loglevel => 'DEBUG', hostname => $host );
push @params, ( allow_mount => 0, discover_volumes => 1 );

my $obj = SDM::Utility::SNMP::DiskUsage->create( @params );
ok( defined $obj->exec, "ok: snmpwalk found");

my $line = 'GPFS-MIB::gpfsNodeName."linuscs107.gsc.wustl.edu" = STRING: "linuscs107.gsc.wustl.edu"';
my $hash = $obj->_parse_snmp_line( $line );
my $expected = {
    'value' => '"linuscs107.gsc.wustl.edu"',
    'oid' => 'gpfsNodeName',
    'type' => 'STRING',
    'idx' => '"linuscs107.gsc.wustl.edu"',
    'mib' => 'GPFS-MIB'
};
ok( is_deeply( $hash, $expected, "ok: is_deeply"), "ok: line parses");

$line = 'GPFS-MIB::gpfsFileSDMPerfName."gpfsdev14" = STRING: "gpfsdev14"';
$hash = $obj->_parse_snmp_line( $line );
$expected = {
    'value' => '"gpfsdev14"',
    'oid' => 'gpfsFileSDMPerfName',
    'type' => 'STRING',
    'idx' => '"gpfsdev14"',
    'mib' => 'GPFS-MIB'
};
ok( is_deeply( $hash, $expected, "ok: is_deeply"), "ok: line parses");

$line = 'GPFS-MIB::gpfsFileSDMBytesReadL."system" = Gauge32: 0';
$hash = $obj->_parse_snmp_line( $line );
$expected = {
    'value' => '0',
    'oid' => 'gpfsFileSDMBytesReadL',
    'type' => 'Gauge32',
    'idx' => '"system"',
    'mib' => 'GPFS-MIB'
};
ok( is_deeply( $hash, $expected, "ok: is_deeply"), "ok: line parses");

$line = 'SNMPv2-MIB::sysDescr.0 = STRING: NetApp Release 7.3.2: Thu Oct 15 04:12:15 PDT 2009';
$hash = $obj->_parse_snmp_line( $line );
$expected = {
    'value' => 'NetApp Release 7.3.2: Thu Oct 15 04:12:15 PDT 2009',
    'oid' => 'sysDescr',
    'type' => 'STRING',
    'idx' => '0',
    'mib' => 'SNMPv2-MIB'
};
ok( is_deeply( $hash, $expected, "ok: is_deeply"), "ok: line parses");

$line = 'SNMPv2-MIB::sysDescr.0 = STRING: Linux linuscs107 2.6.18-194.8.1.el5 #1 SMP Wed Jun 23 10:52:51 EDT 2010 x86_64';
$hash = $obj->_parse_snmp_line( $line );
$expected = {
    'value' => 'Linux linuscs107 2.6.18-194.8.1.el5 #1 SMP Wed Jun 23 10:52:51 EDT 2010 x86_64',
    'oid' => 'sysDescr',
    'type' => 'STRING',
    'idx' => '0',
    'mib' => 'SNMPv2-MIB'
};
ok( is_deeply( $hash, $expected, "ok: is_deeply"), "ok: line parses");

$line = 'GPFS-MIB::gpfsNodeVersion."blade12-4-15.gsc.wustl.edu" = ""';
$hash = $obj->_parse_snmp_line( $line );
$expected = {
    'value' => '""',
    'oid' => 'gpfsNodeVersion',
    'type' => undef,
    'idx' => '"blade12-4-15.gsc.wustl.edu"',
    'mib' => 'GPFS-MIB'
};
ok( is_deeply( $hash, $expected, "ok: is_deeply"), "ok: line parses");

my $ref;
lives_ok { $ref = $obj->read_snmp_into_table('gpfsMIBObjects') } "ok: lives";
#print Data::Dumper::Dumper $ref;
lives_ok { $ref = $obj->read_snmp_into_table('gpfsFileSDMPerfTable') } "ok: lives";
#print Data::Dumper::Dumper $ref;
lives_ok { $ref = $obj->read_snmp_into_table('gpfsDiskPerfTable') } "ok: lives";
#print Data::Dumper::Dumper $ref;
lives_ok { $ref = $obj->acquire_volume_data() } "ok: lives";
ok( scalar keys %$ref > 1, "got data");
#print Data::Dumper::Dumper $ref;

done_testing();
