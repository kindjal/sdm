#! /usr/bin/perl

use Test::More;
use FindBin;
use File::Basename qw/dirname/;

my $top = dirname $FindBin::Bin;
my $base = "$top/lib/System";

print "flush sqlite3 DB\n";
unlink "$base/DataSource/Disk.sqlite3";
unlink "$base/DataSource/Disk.sqlite3-dump";
unlink "$base/DataSource/Disk.sqlite3n";
unlink "$base/DataSource/Disk.sqlite3n-dump";

print "flush and remake Meta\n";
unlink "$base/DataSource/Meta.sqlite3";
unlink "$base/DataSource/Meta.sqlite3n";
unlink "$base/DataSource/Meta.sqlite3-dump";
unlink "$base/DataSource/Meta.sqlite3n-dump";

print "make new sqlite3 DB\n";
system("sqlite3 $base/DataSource/Disk.sqlite3n < $base/DataSource/Disk.sqlite3n-schema");
ok( $? >> 8 == 0, "make new DB ok");
system("sqlite3 $base/DataSource/Disk.sqlite3n .dump > $base/DataSource/Disk.sqlite3n-dump");
ok( $? >> 8 == 0, "make new DB dump ok");
done_testing();
