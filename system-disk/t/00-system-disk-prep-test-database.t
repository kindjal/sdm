#!/usr/bin/perl

use Test::More;
use FindBin;
use File::Basename qw/dirname/;
use IPC::Cmd qw/can_run/;
use Data::Dumper;

$ENV{SYSTEM_DEPLOYMENT}='testing';

my $top = dirname $FindBin::Bin;
my $base = "$top/lib/System";
my $perl = "$^X -I $top/lib -I $top/../system/lib";
my $system = can_run("system");
ok( defined $system, "ok: system found in PATH");

sub runcmd {
    my $command = shift;
    $ENV{SYSTEM_NO_REQUIRE_USER_VERIFY}=1;
    print("$command\n");
    system("$command");
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

use_ok( 'System', "ok: loaded System");
use_ok( 'System::DataSource::Disk', "ok: loaded System::DataSource::Disk");
my $ds = System::DataSource::Disk->get();
my $driver = $ds->driver;

if ($driver eq "SQLite") {
    print "flush sqlite3 DB\n";
    unlink "$base/DataSource/Disk.sqlite3";
    unlink "$base/DataSource/Disk.sqlite3-dump";
    unlink "$base/DataSource/Disk.sqlite3n";
    unlink "$base/DataSource/Disk.sqlite3n-dump";
    print "make new sqlite3 DB\n";
    runcmd("/usr/bin/sqlite3 $base/DataSource/Disk.sqlite3n < $base/DataSource/Disk.sqlite3n.schema");
    runcmd("/usr/bin/sqlite3 $base/DataSource/Disk.sqlite3n .dump > $base/DataSource/Disk.sqlite3n-dump");
}

if ($driver eq "Pg") {
    print "flush and remake psql DB\n";
    runcmd("/usr/bin/psql -w -d system -U system < $base/DataSource/Disk.psql.schema >/dev/null");
}

if ($driver eq "Oracle") {
    print "Use Oracle DB\n";
    open FILE, "<$base/DataSource/Disk.oracle.schema";
    my $sql = do { local $/; <FILE> };
    close(FILE);
    my $login = $ds->login;
    my $auth = $ds->auth;
    open ORA, "| sqlplus -s $login/$auth\@gcdev" or die "Can't pipe to sqlplus: $!";
    print ORA $sql;
    print ORA "exit";
    close(ORA);
}

print "flush and remake Meta\n";
unlink "$base/DataSource/Meta.sqlite3";
unlink "$base/DataSource/Meta.sqlite3n";
unlink "$base/DataSource/Meta.sqlite3-dump";
unlink "$base/DataSource/Meta.sqlite3n-dump";

done_testing();
