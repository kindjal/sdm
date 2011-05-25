#! /usr/bin/perl

use Test::More;
use Test::Output;
use IPC::Cmd;
use File::Basename qw/dirname/;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
    $ENV{SDM_NO_REQUIRE_USER_VERIFY} = 1;
};

my $top = dirname __FILE__;
require "$top/sdm-lib.pm";

my $t = SDM::Test::Lib->new();
my $perl = $t->{perl};
my $sdm = $t->{sdm};

# Start with a fresh database
ok( $t->testinit == 0, "ok: init db");

# -- Now we're prepped, run some commands

# More complicated tests of foreign key constraints and order of ops.
# array host filer group volume
$t->runcmd("$perl $sdm disk group add --name SYSTEMS");
$t->runcmd("$perl $sdm disk filer add --name gpfs-dev");
$t->runcmd("$perl $sdm disk host add --hostname linuscs107");
$t->runcmd("$perl $sdm disk array add --name nsams2k1");
$t->runcmd("$perl $sdm disk volume add --mount-path=/gscmnt/gc2111 --physical-path=/vol/gc2111 --total-kb=6438990688 --used-kb=5722964896 --filername=gpfs-dev --disk-group=SYSTEMS");

# Assign and detach: arrays and hosts
$t->runcmd("$perl $sdm disk array assign nsams2k1 linuscs107");
$t->runcmd("$perl $sdm disk host assign linuscs107 gpfs-dev");
$t->runcmd("$perl $sdm disk host update --master linuscs107");

# Delete a filer that has mappings to volumes hosts and arrays
$t->runcmd("$perl $sdm disk host list --filter hostname=linuscs107 --show hostname,gpfs_node_config.gpfsNodeType,gpfs_node_config.gpfsNodeAdmin");

done_testing();
