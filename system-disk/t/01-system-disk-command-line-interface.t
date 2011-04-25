#! /usr/bin/perl

use Test::More;
use Test::Output;
use FindBin;
use IPC::Cmd;
use File::Basename qw/dirname/;
my $top = dirname __FILE__;
require "$top/system-lib.pm";
my $t = System::Test::Lib->new();
my $perl = $t->{perl};
my $system = $t->{system};
# Start with a fresh database
ok( $t->testinit == 0, "ok: init db");

# -- Now we're prepped, run some commands

# The following create a few entries to build 2 filers the way we know they should look.

$t->runcmd("$perl $system disk group add --name SYSTEMS");
$t->runcmd("$perl $system disk group add --name INFO_APIPE");
$t->runcmd("$perl $system disk group add --name SYSTEMSDEL");
stdout_like { $t->runcmd("$perl $system disk group list --noheaders --show name --filter name=SYSTEMSDEL"); } qr/SYSTEMSDEL/, "ok: group list works";
$ENV{SYSTEM_NO_REQUIRE_USER_VERIFY}=1;

$t->runcmd("$perl $system disk filer add --name gpfs");
$t->runcmd("$perl $system disk filer add --name gpfs2");
stdout_like { $t->runcmd("$perl $system disk filer list --noheaders --show name --filter name=gpfs"); } qr/gpfs/, "ok: filer list works";

$t->runcmd("$perl $system disk host add --hostname linuscs103");
$t->runcmd("$perl $system disk host add --hostname linuscs104");
$t->runcmd("$perl $system disk host add --hostname linuscs105");
$t->runcmd("$perl $system disk host add --hostname linuscs106");
$t->runcmd("$perl $system disk host add --hostname linuscs110");
$t->runcmd("$perl $system disk host add --hostname linuscs111");
$t->runcmd("$perl $system disk host add --hostname linuscs112");
$t->runcmd("$perl $system disk host add --hostname linuscs113");
$t->runcmd("$perl $system disk host add --hostname linuscs114");
stdout_like { $t->runcmd("$perl $system disk host list --noheaders --show hostname --filter hostname=linuscs103"); } qr/linuscs103/, "ok: host list works";

$t->runcmd("$perl $system disk array add --name nsams2k1");
$t->runcmd("$perl $system disk array add --name nsams2k2");
$t->runcmd("$perl $system disk array add --name nsams2k3");
$t->runcmd("$perl $system disk array add --name nsams2k4");
$t->runcmd("$perl $system disk array add --name nsams2k5");
$t->runcmd("$perl $system disk array add --name nsams2k6");
stdout_like { $t->runcmd("$perl $system disk array list --noheaders --show name --filter name=nsams2k1"); } qr/nsams2k1/, "ok: array list works";

$t->runcmd("$perl $system disk array assign nsams2k1 linuscs103");
$t->runcmd("$perl $system disk array assign nsams2k1 linuscs104");
$t->runcmd("$perl $system disk array assign nsams2k1 linuscs105");
$t->runcmd("$perl $system disk array assign nsams2k1 linuscs106");
$t->runcmd("$perl $system disk array assign nsams2k4 linuscs103");
$t->runcmd("$perl $system disk array assign nsams2k4 linuscs104");
$t->runcmd("$perl $system disk array assign nsams2k4 linuscs105");
$t->runcmd("$perl $system disk array assign nsams2k4 linuscs106");

$t->runcmd("$perl $system disk array assign nsams2k2 linuscs110");
$t->runcmd("$perl $system disk array assign nsams2k2 linuscs111");
$t->runcmd("$perl $system disk array assign nsams2k2 linuscs112");
$t->runcmd("$perl $system disk array assign nsams2k2 linuscs113");
$t->runcmd("$perl $system disk array assign nsams2k2 linuscs114");

$t->runcmd("$perl $system disk array assign nsams2k5 linuscs110");
$t->runcmd("$perl $system disk array assign nsams2k5 linuscs111");
$t->runcmd("$perl $system disk array assign nsams2k5 linuscs112");
$t->runcmd("$perl $system disk array assign nsams2k5 linuscs113");
$t->runcmd("$perl $system disk array assign nsams2k5 linuscs114");

$t->runcmd("$perl $system disk host assign linuscs103 gpfs");
$t->runcmd("$perl $system disk host assign linuscs104 gpfs");
$t->runcmd("$perl $system disk host assign linuscs105 gpfs");
$t->runcmd("$perl $system disk host assign linuscs106 gpfs");

$t->runcmd("$perl $system disk host assign linuscs110 gpfs2");
$t->runcmd("$perl $system disk host assign linuscs111 gpfs2");
$t->runcmd("$perl $system disk host assign linuscs112 gpfs2");
$t->runcmd("$perl $system disk host assign linuscs113 gpfs2");
$t->runcmd("$perl $system disk host assign linuscs114 gpfs2");

$t->runcmd("$perl $system disk volume add --mount-path=/gscmnt/ams1100 --physical-path=/vol/ams1100 --total-kb=6438990688 --used-kb=5722964896 --filername=gpfs --disk-group=SYSTEMS");
# Note mixed case group name which is fixed in Volume.pm
$t->runcmd("$perl $system disk volume add --mount-path=/gscmnt/ams1101 --physical-path=/vol/ams1101 --total-kb=18438990688 --used-kb=7722964896 --filername=gpfs --disk-group=SYSTems");

$t->runcmd("$perl $system disk volume add --mount-path=/gscmnt/gc2100 --physical-path=/vol/gc2100 --total-kb=6438990688 --used-kb=5722964896 --filername=gpfs2 --disk-group=INFO_APIPE");
$t->runcmd("$perl $system disk volume add --mount-path=/gscmnt/gc2101 --physical-path=/vol/gc2101 --total-kb=16438990688 --used-kb=11722964896 --filername=gpfs2 --disk-group=INFO_APIPE");

done_testing();
