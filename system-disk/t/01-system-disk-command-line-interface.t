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

sub runcmd {
    my $command = shift;
    print "$system $command\n";
    system("$perl $system $command");
    ok( $? >> 8 == 0, "ok: $command") or die;
    UR::Context->commit() or die;
}

runcmd("disk group add --name SYSTEMS");

runcmd("disk group add --name INFO_APIPE");

runcmd("disk filer add --name nfs11");

runcmd("disk filer add --name nfs12");

runcmd("disk host add --hostname nfs11");

runcmd("disk array add --name GCEVA3");

runcmd("disk array add --name GCEVA2");

runcmd("disk volume add --mount-path=/gscmnt/sata821 --total-kb=6438990688 --used-kb=5722964896 --filername nfs11 --physical-path=/vol/sata821 --disk-group=SYSTEMS");

# Note mixed case group name which is fixed in Volume.pm
runcmd("disk volume add --mount-path=/gscmnt/sata822 --total-kb=6438990688 --used-kb=5722964896 --filername nfs11 --physical-path=/vol/sata822 --disk-group=SyStEmS");

runcmd("disk volume add --mount-path=/gscmnt/sata821 --total-kb=6438990688 --used-kb=5722964896 --filername nfs12 --physical-path=/vol/sata821 --disk-group=SYSTEMS");

runcmd("disk volume add --mount-path=/gscmnt/sata823 --total-kb=6438990688 --used-kb=5722964896 --filername nfs12 --physical-path=/vol/sata823 --disk-group=INFO_APIPE");

done_testing();
