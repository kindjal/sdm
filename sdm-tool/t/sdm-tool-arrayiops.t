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

my $table = "$top/../sdm/t/ifDescr.txt";
my $snmp = SDM::Utility::SNMP->create( hostname => 'localhost', unittest => 1 );
$snmp->tabledata( slurp($table) );
my $a = $snmp->read_snmp_into_table('ifDescr');

$table = "$top/../sdm/t/ifHCInUcastPkts.txt";
$snmp->tabledata( slurp($table) );
my $b = $snmp->read_snmp_into_table('ifHCInUcastPkts');

$table = "$top/../sdm/t/ifHCOutUcastPkts.txt";
$snmp->tabledata( slurp($table) );
my $c = $snmp->read_snmp_into_table('ifHCOutUcastPkts');
my $result;

while (my ($k,$v) = each %$a) {
    $result->{$k} = $v;
}
while (my ($k,$v) = each %$b) {
    $result->{$k} = { %{$result->{$k}}, %$v };
}
while (my ($k,$v) = each %$c) {
    $result->{$k} = { %{$result->{$k}}, %$v };
}

my $t = SDM::Tool::Command::ArrayIops->create( hostname => 'localhost', fcport => 'fc1/1', loglevel => 'DEBUG' );
my ($write,$read) = $t->calculate( $result, "fc1/1" );
ok( $write eq '799051318.039062', 'write ok' );
ok( $read eq '1234676475.46875', 'read ok' );

done_testing();
