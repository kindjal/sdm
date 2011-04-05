#!/usr/bin/perl

use Test::More;
use FindBin;
use File::Basename qw/dirname/;

my $top = dirname $FindBin::Bin;
my $base = "$top/lib/System";

sub runcmd {
    my $command = shift;
    $ENV{SYSTEM_NO_REQUIRE_USER_VERIFY}=1;
    print("$perl $system $command\n");
    system("$perl $system $command");
    if ($? == -1) {
         print "failed to execute: $!\n";
    } elsif ($? & 127) {
         printf "child died with signal %d, %s coredump\n",
             ($? & 127),  ($? & 128) ? 'with' : 'without';
    } else {
         printf "child exited with value %d\n", $? >> 8;
    }
    ok( $? >> 8 == 0, "ok: $command") or die;
}

print "flush sqlite3 DB\n";
unlink "$base/DataSource/Disk.sqlite3";
unlink "$base/DataSource/Disk.sqlite3-dump";
unlink "$base/DataSource/Disk.sqlite3n";
unlink "$base/DataSource/Disk.sqlite3n-dump";

print "flush and remake psql DB\n";
runcmd("psql -w -d system -U system < $base/DataSource/Disk.psql-schema >/dev/null");

print "flush and remake Meta\n";
unlink "$base/DataSource/Meta.sqlite3";
unlink "$base/DataSource/Meta.sqlite3n";
unlink "$base/DataSource/Meta.sqlite3-dump";
unlink "$base/DataSource/Meta.sqlite3n-dump";

print "make new sqlite3 DB\n";
runcmd("sqlite3 $base/DataSource/Disk.sqlite3n < $base/DataSource/Disk.sqlite3n-schema");
runcmd("sqlite3 $base/DataSource/Disk.sqlite3n .dump > $base/DataSource/Disk.sqlite3n-dump");
done_testing();
