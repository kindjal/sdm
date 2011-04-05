#! /usr/bin/perl

use Test::More;
use Test::Output;
use FindBin;
use IPC::Cmd;
use File::Basename qw/dirname/;

my $top = dirname $FindBin::Bin;

# Preserve the -I args we used to run this script.
my $perl = "$^X -I $top/lib -I $top/../system/lib";
my $system = IPC::Cmd::can_run("system");
unless ($system) {
    if (-e "./system-disk/system/bin/system") {
        $system = "./system-disk/system/bin/system";
    } elsif (-e "./system/bin/system") {
        $system = "./system/bin/system";
    } elsif (-e "../system/bin/system") {
        $system = "../system/bin/system";
    } else {
        die "Can't find 'system' executable";
    }
}

use_ok( 'System' ) or die "Run with -I to include system/lib";
use_ok( 'System::Disk' ) or die "Run with -I to include system-disk/lib";

# Use same perl invocation to run this
system("$perl $top/t/00-system-disk-prep-test-database.t");
ok( $? >> 8 == 0, "ok: $command") or die "Cannot remake test DB";

# -- Now we're prepped, run some commands

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
    UR::Context->commit() or die;
}

runcmd("disk group add --name SYSTEMS");
runcmd("disk group add --name INFO_APIPE");
runcmd("disk group add --name SYSTEMSDEL");
stdout_like { runcmd("disk group list --noheaders --show name --filter name=SYSTEMSDEL"); } qr/SYSTEMSDEL/, "ok: group list works";
$ENV{SYSTEM_NO_REQUIRE_USER_VERIFY}=1;

runcmd("disk filer add --name gpfs");
runcmd("disk filer add --name gpfs2");
stdout_like { runcmd("disk filer list --noheaders --show name --filter name=gpfs"); } qr/gpfs/, "ok: filer list works";

runcmd("disk host add --hostname linuscs103");
runcmd("disk host add --hostname linuscs104");
runcmd("disk host add --hostname linuscs105");
runcmd("disk host add --hostname linuscs106");
runcmd("disk host add --hostname linuscs110");
runcmd("disk host add --hostname linuscs111");
runcmd("disk host add --hostname linuscs112");
runcmd("disk host add --hostname linuscs113");
runcmd("disk host add --hostname linuscs114");
stdout_like { runcmd("disk host list --noheaders --show hostname --filter hostname=linuscs103"); } qr/linuscs103/, "ok: host list works";

runcmd("disk array add --name nsams2k1");
runcmd("disk array add --name nsams2k2");
runcmd("disk array add --name nsams2k3");
runcmd("disk array add --name nsams2k4");
runcmd("disk array add --name nsams2k5");
runcmd("disk array add --name nsams2k6");
stdout_like { runcmd("disk array list --noheaders --show name --filter name=nsams2k1"); } qr/nsams2k1/, "ok: array list works";

runcmd("disk array assign nsams2k1 linuscs103");
runcmd("disk array assign nsams2k1 linuscs104");
runcmd("disk array assign nsams2k1 linuscs105");
runcmd("disk array assign nsams2k1 linuscs106");
runcmd("disk array assign nsams2k4 linuscs103");
runcmd("disk array assign nsams2k4 linuscs104");
runcmd("disk array assign nsams2k4 linuscs105");
runcmd("disk array assign nsams2k4 linuscs106");

runcmd("disk array assign nsams2k2 linuscs110");
runcmd("disk array assign nsams2k2 linuscs111");
runcmd("disk array assign nsams2k2 linuscs112");
runcmd("disk array assign nsams2k2 linuscs113");
runcmd("disk array assign nsams2k2 linuscs114");

runcmd("disk array assign nsams2k5 linuscs110");
runcmd("disk array assign nsams2k5 linuscs111");
runcmd("disk array assign nsams2k5 linuscs112");
runcmd("disk array assign nsams2k5 linuscs113");
runcmd("disk array assign nsams2k5 linuscs114");

runcmd("disk host assign linuscs103 gpfs");
runcmd("disk host assign linuscs104 gpfs");
runcmd("disk host assign linuscs105 gpfs");
runcmd("disk host assign linuscs106 gpfs");

runcmd("disk host assign linuscs110 gpfs2");
runcmd("disk host assign linuscs111 gpfs2");
runcmd("disk host assign linuscs112 gpfs2");
runcmd("disk host assign linuscs113 gpfs2");
runcmd("disk host assign linuscs114 gpfs2");

runcmd("disk volume add --mount-path=/gscmnt/ams1100 --physical-path=/vol/ams1100 --total-kb=6438990688 --used-kb=5722964896 --filername=gpfs --disk-group=SYSTEMS");
# Note mixed case group name which is fixed in Volume.pm
runcmd("disk volume add --mount-path=/gscmnt/ams1101 --physical-path=/vol/ams1101 --total-kb=18438990688 --used-kb=7722964896 --filername=gpfs --disk-group=SYSTems");

runcmd("disk volume add --mount-path=/gscmnt/gc2100 --physical-path=/vol/gc2100 --total-kb=6438990688 --used-kb=5722964896 --filername=gpfs2 --disk-group=INFO_APIPE");
runcmd("disk volume add --mount-path=/gscmnt/gc2101 --physical-path=/vol/gc2101 --total-kb=16438990688 --used-kb=11722964896 --filername=gpfs2 --disk-group=INFO_APIPE");

done_testing();
