#! /usr/bin/perl

use Test::More;
use FindBin;
use IPC::Cmd;
use File::Basename qw/dirname/;

my $top = dirname $FindBin::Bin;
my $base = "$top/lib/System";

# Preserve the -I args we used to run this script.
my $perl = "$^X -I " . join(" -I ",@INC);
my $system = IPC::Cmd::can_run("system");
unless ($system) {
    if (-e "../system/bin/system") {
        $system = "../system/bin/system"
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
    print "$system $command\n";
    system("$perl $system $command");
    ok( $? >> 8 == 0, "ok: $command") or die;
    UR::Context->commit() or die;
}

runcmd("disk group add --name SYSTEMS");
runcmd("disk group add --name INFO_APIPE");

runcmd("disk filer add --name gpfs");
runcmd("disk filer add --name gpfs2");

runcmd("disk host add --hostname linuscs103");
runcmd("disk host add --hostname linuscs104");
runcmd("disk host add --hostname linuscs105");
runcmd("disk host add --hostname linuscs106");

runcmd("disk host add --hostname linuscs110");
runcmd("disk host add --hostname linuscs111");
runcmd("disk host add --hostname linuscs112");
runcmd("disk host add --hostname linuscs113");
runcmd("disk host add --hostname linuscs114");

runcmd("disk array add --name nsams2k1");
runcmd("disk array add --name nsams2k2");
runcmd("disk array add --name nsams2k3");
runcmd("disk array add --name nsams2k4");
runcmd("disk array add --name nsams2k5");
runcmd("disk array add --name nsams2k6");

runcmd("disk volume add --mount-path=/gscmnt/ams1100 --physical-path=/vol/ams1100 --total-kb=6438990688 --used-kb=5722964896 --filername gpfs --disk-group=SYSTEMS");
# Note mixed case group name which is fixed in Volume.pm
runcmd("disk volume add --mount-path=/gscmnt/ams1101 --physical-path=/vol/ams1101 --total-kb=18438990688 --used-kb=7722964896 --filername gpfs --disk-group=SYSTems");

runcmd("disk volume add --mount-path=/gscmnt/gc2100 --physical-path=/vol/gc2100 --total-kb=6438990688 --used-kb=5722964896 --filername gpfs2 --disk-group=INFO_APIPE");
runcmd("disk volume add --mount-path=/gscmnt/gc2101 --physical-path=/vol/gc2101 --total-kb=16438990688 --used-kb=11722964896 --filername gpfs2 --disk-group=INFO_APIPE");

done_testing();
