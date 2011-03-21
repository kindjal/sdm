
package System::Utility::SNMP::TestSuite;

# Standard modules for my unit test suites
# use base 'Test::Builder::Module';

use strict;
use warnings;

use above "System";

use Test::More;
use Test::Output;
use Test::Exception;

use Data::Dumper;
use Cwd qw/abs_path/;
use File::Basename qw/dirname/;
#use Log::Log4perl qw/:levels/;

use System::Utility::SNMP;

my $live = 1;
my $count = 0;
my $thisfile = Cwd::abs_path(__FILE__);
my $cwd = dirname $thisfile;

my $obj;
my $host;
my $res;
my $result = {};
my $oid;
my $physical_path;
my $mount_path;
my $group;

$obj = System::Utility::SNMP->create();

throws_ok { $obj->connect_snmp("foohost"); } qr/SNMP failed/, "test_connect: fails ok on bad host";
lives_ok { $obj->connect_snmp("ntap11"); } "test_connect: ok on nost nap11";

$host = "gpfs";
$res = $obj->connect_snmp($host);
$res = $obj->snmp_get_table('1.3.6.1.2.1.25.4.2.1.2');
ok( scalar @{ [ keys %$res ] } > 1, "test snmp_get_table" );

# Only use this test during development when you know
# we can connect to target host;
$host = "nfs17";
$res = $obj->connect_snmp($host);
$res = $obj->snmp_get_request( ['1.3.6.1.2.1.1.1.0', '1.3.6.1.2.1.1.5.0']);
ok( $res->{ '1.3.6.1.2.1.1.1.0' } =~ /^Linux/, "test_snmp_get_request: nfs17 is linux");
ok( $res->{ '1.3.6.1.2.1.1.5.0' } eq 'linuscs84', "test_snmp_get_request: sysDesc is linuxcs84");

$host = "nfs24";
$res = $obj->connect_snmp($host);
$oid = '1.3.6.1.2.1.25.2.3.1.3';
$res = $obj->snmp_get_serial_request( $oid );
ok( scalar @{ [ keys %$res ] } == 98, "test_snmp_get_serial_request: ok");

my $string = "This is an unrecognized sysDescr string";
throws_ok { $obj->type_string_to_type($string); } qr/No such host/, "test_type_mapper: fails ok on bad host type";
$string = "NetApp Release 7.3.2: Thu Oct 15 04:12:15 PDT 2009";
$res = $obj->type_string_to_type($string);
ok($res = 'linux',"test_type_mapper: sees netapp ok");

$host = "nfs17";
$obj->connect_snmp($host);
$res = $obj->get_host_type($host);
ok( $res eq 'linux', "test_get_host_type: linux detected" );

$host = "ntap8";
$obj->connect_snmp($host);
$res = $obj->get_host_type($host);
ok( $res eq 'netapp', "test_get_host_type: ntap8 detected" );

$host = "nfs11";
$obj->connect_snmp($host);
$obj->get_snmp_disk_usage($result);
ok( scalar keys %$result > 1, "test_get_snmp_disk_usage: $host ok");

$host = "ntap8";
$obj->connect_snmp($host);
$obj->get_snmp_disk_usage($result);
ok( scalar keys %$result > 1, "test_get_snmp_disk_usage: $host ok");

$host = "ntap9";
lives_ok { $result = $obj->query_snmp( filer => $host ); } "test_target: $host runs ok";
ok( ref $result eq 'HASH', "test target" );

$host = "nfs11";
$physical_path = "/vol/sata840";
$mount_path = "/gscmnt/sata840";
lives_ok { $result = $obj->query_snmp( filer => $host, physical_path => $physical_path ); } "query_snmp: runs ok";
lives_ok { $group = $obj->get_disk_group($physical_path,$mount_path); } "test_snmp_get_disk_group: query ok";

done_testing();
