use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use SDM;

use Test::More;
use Test::Output;
use Test::Exception;

use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
#require "$top/t/sdm-tools-lib.pm";

sub slurp {
    my $filename = shift;
    my $content;
    open(FH,"<$filename") or die "open failed: $!";
    $content = do { local $/; <FH> };
    close(FH);
    my @content = split("\n",$content);
    return \@content;
}

my $table = "$top/t/ifTable.txt";
my $snmp = SDM::Utility::SNMP->create( hostname => 'localhost', sloppy => 1 );
$snmp->tabledata( slurp($table) );
my $result = $snmp->read_snmp_into_table('ifTable');
my $obj = $result->{19951616};
my $expected;
$expected->{ifIndex} = '19951616';
$expected->{ifDescr} = 'fc7/8';
$expected->{ifType} = 'fibreChannel(56)';
$expected->{ifMtu} = '2112';
$expected->{ifSpeed} = '0';
$expected->{ifPhysAddress} = '21:88:0:d:ec:82:2a:40';
$expected->{ifAdminStatus} = 'down(2)';
$expected->{ifOperStatus} = 'down(2)';
$expected->{ifLastChange} = '(0) 0:00:00.00';
$expected->{ifInOctets} = '116';
$expected->{ifInUcastPkts} = '1';
$expected->{ifInNUcastPkts} = '0';
$expected->{ifInDiscards} = '0';
$expected->{ifInErrors} = '0';
$expected->{ifInUnknownProtos} = '0';
$expected->{ifOutOctets} = '116';
$expected->{ifOutUcastPkts} = '11453220';
$expected->{ifOutNUcastPkts} = '0';
$expected->{ifOutDiscards} = '0';
$expected->{ifOutErrors} = '0';
$expected->{ifOutQLen} = '0';
$expected->{ifSpecific} = 'SNMPv2-SMI::zeroDotZero';
ok( is_deeply( $obj, $expected, "is_deeply" ), "objects match" );

$table = "$top/t/hrStorageTable.txt";
$snmp->tabledata( slurp($table) );
$result = $snmp->read_snmp_into_table('hrStorageTable');
$obj = $result->{207};
$expected = {};
$expected->{hrStorageIndex} = '207';
$expected->{hrStorageType} = 'HOST-RESOURCES-TYPES::hrStorageFixedDisk';
$expected->{hrStorageDescr} = '/vol/gpfs-arx-metadata';
$expected->{hrStorageAllocationUnits} = '16384 Bytes';
$expected->{hrStorageSize} = '20166480';
$expected->{hrStorageUsed} = '1398713';
ok( is_deeply( $obj, $expected, "is_deeply" ), "objects match" );

$table = "$top/t/dfTable.txt";
$snmp->tabledata( slurp($table) );
$result = $snmp->read_snmp_into_table('dfTable');
$obj = $result->{56};
$expected = {};
$expected->{dfIndex} = '56';
$expected->{dfFileSys} = '/vol/arx_quorum/.snapshot';
$expected->{dfKBytesTotal} = '0';
$expected->{dfKBytesUsed} = '6396';
$expected->{dfKBytesAvail} = '0';
$expected->{dfPerCentKBytesCapacity} = '0';
$expected->{dfInodesUsed} = '0';
$expected->{dfInodesFree} = '0';
$expected->{dfPerCentInodeCapacity} = '0';
$expected->{dfMountedOn} = '/vol/arx_quorum/.snapshot';
$expected->{dfMaxFilesAvail} = '622580';
$expected->{dfMaxFilesUsed} = '105';
$expected->{dfMaxFilesPossible} = '4980717';
$expected->{dfHighTotalKBytes} = '0';
$expected->{dfLowTotalKBytes} = '0';
$expected->{dfHighUsedKBytes} = '0';
$expected->{dfLowUsedKBytes} = '6396';
$expected->{dfHighAvailKBytes} = '0';
$expected->{dfLowAvailKBytes} = '0';
$expected->{dfStatus} = 'mounted(2)';
$expected->{dfMirrorStatus} = 'invalid(1)';
$expected->{dfPlexCount} = '0';
$expected->{dfType} = 'flexibleVolume(2)';
$expected->{dfHighSisSharedKBytes} = '0';
$expected->{dfLowSisSharedKBytes} = '0';
$expected->{dfHighSisSavedKBytes} = '0';
$expected->{dfLowSisSavedKBytes} = '0';
$expected->{dfPerCentSaved} = '0';
$expected->{df64TotalKBytes} = '0';
$expected->{df64UsedKBytes} = '6396';
$expected->{df64AvailKBytes} = '17179862788';
$expected->{df64SisSharedKBytes} = '0';
$expected->{df64SisSavedKBytes} = '0';
ok( is_deeply( $obj, $expected, "is_deeply" ), "objects match" );

done_testing();
