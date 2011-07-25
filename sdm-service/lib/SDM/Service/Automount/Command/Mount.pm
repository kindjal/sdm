
use strict;
use warnings;

use DBD::SQLite;
use Getopt::Std;
use Data::Dumper;

sub usage {
    print <<EOF;
Usage:
    $0 [options] volume
    -h     This helpful message
    -f     Filename containing SQLite DB
EOF
};

my %opts;
getopts("hf:",\%opts) or usage;
if (delete $opts{h}) { usage; exit 1; }

my $filename = delete $opts{f};
die "error: specify DB file with -f" unless ($filename);
open(FD,"<$filename") or die "error: unable to open file: $!";
close(FD);

if (scalar @ARGV != 1) { usage; exit 1; }
my $volume = $ARGV[0];
die "error: no mount point specified" unless ($volume);

my $dbh = DBI->connect( "dbi:SQLite:dbname=$filename" ) or die "error: connect failed: $DBI::errstr";
my $sth = $dbh->prepare( qq/ SELECT * from service_automount WHERE name = ?;/ );

$sth->execute( $volume );
my $volumes = $sth->fetchall_arrayref();
die "error: more than one volume found" if (scalar @$volumes > 1);
die "error: volume not found" if (! @$volumes);
foreach my $volume (@$volumes) {
    print $volume->[1] . " " . $volume->[2] . ":" . $volume->[3] . "\n";
}

1;
