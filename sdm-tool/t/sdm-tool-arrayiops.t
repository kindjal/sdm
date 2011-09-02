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
my $snmp_table = $snmp->read_snmp_into_table('ifTable');

my $t = SDM::Tool::Command::ArrayIops->create( hostname => 'localhost', fcport => 'fc1/1' );
my ($write,$read) = $t->calculate( $snmp_table );
ok($write == 1575893693, "writes match");
ok($read == 2445739607, "reads match");

my $msg = $t->execute( $snmp_table );
warn "" . Data::Dumper::Dumper $msg;

done_testing();
