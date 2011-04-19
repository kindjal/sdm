
package System::Test::Lib;

use strict;
use warnings;
use System;
use Test::More;
use File::Basename qw/dirname/;
use IPC::Cmd qw/can_run/;

my $top = dirname $FindBin::Bin;
my $base = "$top/lib/System";
my $perl = "$^X -I " . join(" -I ",@INC);
my $system = can_run("system");
unless ($system) {
    if (-e "./system-disk/system/bin/system") {
        $system = "./system-disk/system/bin/system";
    } elsif (-e "./system/bin/system") {
        $system = "./system/bin/system";
    } elsif (-e "../system/bin/system") {        $system = "../system/bin/system";    } else {
        die "Can't find 'system' executable";
    }
}

# Start with a fresh database
sub testinit {
    my $self = shift;
    system("$perl $top/t/00-system-disk-prep-test-database.t >&2");
    ok($? >> 8 == 0, "prep test db ok");
    return 0;
}

sub runcmd {
    $ENV{SYSTEM_NO_REQUIRE_USER_VERIFY}=1;
    my $self = shift;
    my $command = shift;
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

1;
