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

# More complicated tests of foreign key constraints and order of ops.
# array host filer group volume
$t->runcmd("$perl $system disk group add --name SYSTEMS");
$t->runcmd("$perl $system disk filer add --name gpfs");
$t->runcmd("$perl $system disk host add --hostname linuscs103");
$t->runcmd("$perl $system disk array add --name nsams2k1");
$t->runcmd("$perl $system disk volume add --mount-path=/gscmnt/ams1100 --physical-path=/vol/ams1100 --total-kb=6438990688 --used-kb=5722964896 --filername=gpfs --disk-group=SYSTEMS");

# Assign and detach: arrays and hosts
$t->runcmd("$perl $system disk array assign nsams2k1 linuscs103");
$t->runcmd("$perl $system disk host assign linuscs103 gpfs");

# Delete a volume that has mappings to filers and arrays
$t->runcmd("$perl $system disk volume delete 1");

done_testing();
