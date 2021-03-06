
package Sdm::Test::Lib;

use strict;
use warnings;

BEGIN {
    # testing means use sqlite db, we do want to commit.
    $ENV{SDM_DEPLOYMENT} ||= "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

use Test::More;
use Cwd qw/abs_path/;
use File::Basename qw/dirname/;
use IPC::Cmd qw/can_run/;
use Data::Dumper;

use_ok( 'Sdm', "ok: loaded Sdm");
use_ok( 'Sdm::DataSource::Service', "ok: loaded Sdm::DataSource::Service");

my $ds = Sdm::DataSource::Service->get();
my $driver = $ds->driver;
my $top = dirname dirname abs_path(__FILE__);
my $base = "$top/lib/Sdm";
my $perl = "$^X -I $top/lib -I $top/../sdm/lib";
my $sdm = can_run("./bin/sdm");
unless ($sdm) {
    if (-e "./sdm-service/sdm/bin/sdm") {
        $sdm = "./sdm-service/sdm/bin/sdm";
    } elsif (-e "./sdm/bin/sdm") {
        $sdm = "./sdm/bin/sdm";
    } elsif (-e "../sdm/bin/sdm") {
        $sdm = "../sdm/bin/sdm";
    } else {
        die "Can't find 'sdm' executable";
    }
}
ok( defined $sdm, "ok: sdm found in PATH");

sub new {
    my $class = shift;
    my $self = {
        'perl' => $perl,
        'sdm' => $sdm,
    };
    bless $self,$class;
    return $self;
}

sub runcmd {
    my $self = shift;
    my $command = shift;
    $ENV{SDM_NO_REQUIRE_USER_VERIFY} ||= 1;
    #print STDERR "$command\n";
    system("$command");
    if ($? == -1) {
         print STDERR "failed to execute: $!\n";
    } elsif ($? & 127) {
         printf STDERR "child died with signal %d, %s coredump\n",
             ($? & 127),  ($? & 128) ? 'with' : 'without';
    } else {
        # printf STDERR "child exited with value %d\n", $? >> 8;
    }
    ok( $? >> 8 == 0, "ok: $command") or die;
}

sub testinit {
    my $self = shift;
    if ($driver eq "SQLite") {
        print "flush sqlite3 DB\n";
        unlink "$base/DataSource/Service.sqlite3";
        unlink "$base/DataSource/Service.sqlite3-dump";
        print "make new sqlite3 DB\n";
        $self->runcmd("/usr/bin/sqlite3 $base/DataSource/Service.sqlite3 < $base/DataSource/Service.sqlite3.schema");
        $self->runcmd("/usr/bin/sqlite3 $base/DataSource/Service.sqlite3 .dump > $base/DataSource/Service.sqlite3-dump");
    }

    if ($driver eq "Pg") {
        print "flush and remake psql DB\n";
        $self->runcmd("/usr/bin/psql -w -d system -U system < $base/DataSource/Service.psql.schema >/dev/null");
    }

    if ($driver eq "Oracle") {
        print "Use Oracle DB\n";
        open FILE, "<$base/DataSource/Service.oracle.schema";
        my $sql = do { local $/; <FILE> };
        close(FILE);
        my $login = $ds->login;
        my $auth = $ds->auth;
        open ORA, "| sqlplus -s $login/$auth\@gcdev" or die "Can't pipe to sqlplus: $!";
        print ORA $sql;
        print ORA "exit";
        close(ORA);
    }

    print "flush and remake Meta\n";
    my $ds = "$top/../sdm/lib/Sdm/DataSource";
    unlink "$ds/Meta.sqlite3";
    unlink "$ds/Meta.sqlite3-dump";
    $self->runcmd("/usr/bin/sqlite3 $ds/Meta.sqlite3 < $ds/Meta.sqlite3-schema");
    $self->runcmd("/usr/bin/sqlite3 $ds/Meta.sqlite3 .dump > $ds/Meta.sqlite3-dump");
    return 0;
}

sub testdata {
    my $self = shift;
    return 0;
}

1;

