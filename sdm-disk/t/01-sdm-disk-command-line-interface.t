#! /usr/bin/perl

use Test::More;
use Test::Output;
use FindBin;
use IPC::Cmd;
use File::Basename qw/dirname/;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
    $ENV{SDM_NO_REQUIRE_USER_VERIFY} = 1;
};

my $top = dirname __FILE__;
require "$top/sdm-disk-lib.pm";
my $t = SDM::Test::Lib->new();
my $perl = $t->{perl};
my $sdm = $t->{sdm};
# Start with a fresh database
ok( $t->testinit == 0, "ok: init db");

# -- Now we're prepped, run some commands

# The following create a few entries to build 2 filers the way we know they should look.

$t->runcmd("$perl $sdm disk group add --name SYSTEMS");
$t->runcmd("$perl $sdm disk group add --name INFO_APIPE");
$t->runcmd("$perl $sdm disk group add --name SYSTEMSDEL");
stdout_like { $t->runcmd("$perl $sdm disk group list --noheaders --show name --filter name=SYSTEMSDEL"); } qr/SYSTEMSDEL/, "ok: group list works";
$ENV{SDM_NO_REQUIRE_USER_VERIFY}=1;

$t->runcmd("$perl $sdm disk filer add --name gpfs");
stdout_like { $t->runcmd("$perl $sdm disk filer list --noheaders --show name --filter name=gpfs"); } qr/gpfs/, "ok: filer list works";

$t->runcmd("$perl $sdm disk host add --hostname linuscs103");
stdout_like { $t->runcmd("$perl $sdm disk host list --noheaders --show hostname --filter hostname=linuscs103"); } qr/linuscs103/, "ok: host list works";

$t->runcmd("$perl $sdm disk array add --name nsams2k1");
stdout_like { $t->runcmd("$perl $sdm disk array list --noheaders --show name --filter name=nsams2k1"); } qr/nsams2k1/, "ok: array list works";

$t->runcmd("$perl $sdm disk array assign nsams2k1 linuscs103");
$t->runcmd("$perl $sdm disk host assign linuscs103 gpfs");

$t->runcmd("$perl $sdm disk volume add --name=ams1100 --physical-path=/vol/ams1100 --total-kb=6438990688 --used-kb=5722964896 --filername=gpfs --disk-group=SYSTEMS");
# Note mixed case group name which is fixed in Volume.pm
$t->runcmd("$perl $sdm disk volume add --name=ams1101 --physical-path=/vol/ams1101 --total-kb=18438990688 --used-kb=7722964896 --filername=gpfs --disk-group=SYSTems");

done_testing();
