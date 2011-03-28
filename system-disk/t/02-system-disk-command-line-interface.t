#! /usr/bin/perl

use Test::More;
use Test::Output;
use FindBin;
use IPC::Cmd;
use File::Basename qw/dirname/;

my $top = dirname $FindBin::Bin;
my $base = "$top/lib/System";

# Preserve the -I args we used to run this script.
my $perl = "$^X -I " . join(" -I ",@INC);
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
    print "$system $command\n";
    system("$perl $system $command");
    ok( $? >> 8 == 0, "ok: $command") or die;
    UR::Context->commit() or die;
}

# Simple add, update, list, delete for all objects.
# array host filer group volume
runcmd("disk group add --name SYSTEMS");
stdout_like { runcmd("disk group list --noheaders --show name --filter name=SYSTEMS"); } qr/SYSTEMS/, "ok: group list works";
runcmd("disk group update --permissions 755 SYSTEMS");

runcmd("disk filer add --name gpfs");
stdout_like { runcmd("disk filer list --noheaders --show name --filter name=gpfs"); } qr/gpfs/, "ok: filer list works";
runcmd("disk filer update --comments Foo gpfs");
runcmd("disk filer list --noheaders --show name --filter name=gpfs");

runcmd("disk host add --hostname linuscs103");
stdout_like { runcmd("disk host list --noheaders --show hostname --filter hostname=linuscs103"); } qr/linuscs103/, "ok: host list works";
runcmd("disk host update --comments Foo linuscs103");

runcmd("disk array add --name nsams2k1");
stdout_like { runcmd("disk array list --noheaders --show name --filter name=nsams2k1"); } qr/nsams2k1/, "ok: array list works";
runcmd("disk array update --model Foo nsams2k1");

runcmd("disk volume add --mount-path=/gscmnt/ams1100 --physical-path=/vol/ams1100 --total-kb=6438990688 --used-kb=5722964896 --filername=gpfs --disk-group=SYSTEMS");
runcmd("disk volume update --total-kb=7438990688 1");
stdout_like { runcmd("disk volume list --noheaders --show mount_path --filter mount_path=/gscmnt/ams1100"); } qr/ams1100/, "ok: volume list works";

runcmd("disk volume delete 1");
runcmd("disk group delete SYSTEMS");
runcmd("disk filer delete gpfs");
runcmd("disk host delete linuscs103");
runcmd("disk array delete nsams2k1");

done_testing();
