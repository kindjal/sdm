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

# Simple add, update, list, delete for all objects.
# array host filer group volume
$t->runcmd("$perl $system disk filer add --name gpfs");
stdout_like { $t->runcmd("$perl $system disk filer list --noheaders --show name --filter name=gpfs"); } qr/gpfs/, "ok: filer list works";
$t->runcmd("$perl $system disk filer update --comments Foo gpfs");
$t->runcmd("$perl $system disk filer list --noheaders --show name --filter name=gpfs");

$t->runcmd("$perl $system disk group add --name SYSTEMS");
stdout_like { $t->runcmd("$perl $system disk group list --noheaders --show name --filter name=SYSTEMS"); } qr/SYSTEMS/, "ok: group list works";
$t->runcmd("$perl $system disk group update --permissions 755 SYSTEMS");

$t->runcmd("$perl $system disk host add --hostname linuscs103");
stdout_like { $t->runcmd("$perl $system disk host list --noheaders --show hostname --filter hostname=linuscs103"); } qr/linuscs103/, "ok: host list works";
$t->runcmd("$perl $system disk host update --comments Foo linuscs103");

$t->runcmd("$perl $system disk array add --name nsams2k1");
stdout_like { $t->runcmd("$perl $system disk array list --noheaders --show name --filter name=nsams2k1"); } qr/nsams2k1/, "ok: array list works";
$t->runcmd("$perl $system disk array update --model Foo nsams2k1");

$t->runcmd("$perl $system disk volume add --mount-path=/gscmnt/ams1100 --physical-path=/vol/ams1100 --total-kb=6438990688 --used-kb=5722964896 --filername=gpfs --disk-group=SYSTEMS");
$t->runcmd("$perl $system disk volume update --total-kb=7438990688 1");
stdout_like { $t->runcmd("$perl $system disk volume list --noheaders --show mount_path --filter mount_path=/gscmnt/ams1100"); } qr/ams1100/, "ok: volume list works";

$t->runcmd("$perl $system disk volume delete 1");
$t->runcmd("$perl $system disk group delete SYSTEMS");
$t->runcmd("$perl $system disk filer delete gpfs");
$t->runcmd("$perl $system disk host delete linuscs103");
$t->runcmd("$perl $system disk array delete nsams2k1");

done_testing();
