
package Sdm::Web::Lib;

use strict;
use warnings;

BEGIN {
    # testing means use sqlite db, we do want to commit.
    $ENV{SDM_DEPLOYMENT} = "testing";
};

use Test::More;
use Cwd qw/abs_path/;
use File::Basename qw/dirname/;
use IPC::Cmd qw/can_run/;
use Data::Dumper;

use Sdm;

my $ds = Sdm::DataSource::Disk->get();
my $driver = $ds->driver;
my $top = dirname dirname abs_path(__FILE__);
my $base = "$top/lib/Sdm";
my $perl = "$^X -I $top/lib -I $top/../sdm/lib";
my $sdm = can_run("./bin/sdm");

unless ($top =~ /\/deploy$/) {
    # We need access to our full compliment of sdm sub modules
    # so we can create sample data and examine the web views.
    plan skip_all => "only run these unit tests from a ./deploy directory";
}

unless ($sdm) {
    if (-e "./sdm-disk/sdm/bin/sdm") {
        $sdm = "./sdm-disk/sdm/bin/sdm";
    } elsif (-e "./sdm/bin/sdm") {
        $sdm = "./sdm/bin/sdm";
    } elsif (-e "../sdm/bin/sdm") {
        $sdm = "../sdm/bin/sdm";
    } else {
        die "Can't find 'sdm' executable";
    }
}

die "sdm not found in PATH" unless (defined $sdm);

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
    print("$command\n");
    system("$command");
    if ($? == -1) {
         print "failed to execute: $!\n";
    } elsif ($? & 127) {
         printf "child died with signal %d, %s coredump\n",
             ($? & 127),  ($? & 128) ? 'with' : 'without';
    } else {
         printf "child exited with value %d\n", $? >> 8;
    }
    ok( $? >> 8 == 0, "ok: $command") or die;
}

sub testinit {
    my $self = shift;
    if ($driver eq "SQLite") {
        print "flush sqlite3 DB\n";
        unlink "$base/DataSource/Disk.sqlite3";
        unlink "$base/DataSource/Disk.sqlite3-dump";
        print "make new sqlite3 DB\n";
        $self->runcmd("/usr/bin/sqlite3 $base/DataSource/Disk.sqlite3 < $base/DataSource/Disk.sqlite3.schema");
        $self->runcmd("/usr/bin/sqlite3 $base/DataSource/Disk.sqlite3 .dump > $base/DataSource/Disk.sqlite3-dump");
    }

    if ($driver eq "Pg") {
        print "flush and remake psql DB\n";
        $self->runcmd("/usr/bin/psql -w -d sdm -U sdm < $base/DataSource/Disk.psql.schema >/dev/null");
    }

    if ($driver eq "Oracle") {
        print "Use Oracle DB\n";
        open FILE, "<$base/DataSource/Disk.oracle.schema";
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

    # Create Disk Filers
    my $filer = Sdm::Disk::Filer->create(name => "gpfs", status => 1, comments => "This is a comment" );
    $filer->created("0000-00-00 00:00:00");
    $filer->last_modified("0000-00-00 00:00:00");
    $filer = Sdm::Disk::Filer->create(name => "gpfs2", status => 1, comments => "This is another comment" );
    $filer->created("0000-00-00 00:00:00");
    $filer->last_modified("0000-00-00 00:00:00");
    $filer = Sdm::Disk::Filer->create(name => "gpfs-dev", status => 1, comments => "This is another comment" );
    $filer->created("0000-00-00 00:00:00");
    $filer->last_modified("0000-00-00 00:00:00");
    my $host = Sdm::Disk::Host->create(hostname => "linuscs103", master => 0);

    # Disk Host
    $host->assign("gpfs");
    $host = Sdm::Disk::Host->create(hostname => "linuscs107", master => 1);
    $host->assign("gpfs-dev");

    # Disk Array
    my $array = Sdm::Disk::Array->create(name => "nsams2k1");
    $array->assign("linuscs103");
    $array = Sdm::Disk::Array->create(name => "nsams2k2");
    $array->assign("linuscs107");

    # Disk Group
    Sdm::Disk::Group->create(name => "SYSTEMS_DEVELOPMENT");
    Sdm::Disk::Group->create(name => "SYSTEMS");
    Sdm::Disk::Group->create(name => "INFO_APIPE");
    Sdm::Disk::Group->create(name => "INFO_GENOME_MODELS");

    # Disk Volume
    # If you change these sample volumes, unit tests expected values will also change.
    Sdm::Disk::Volume->create( mount_path => '/gscmnt/gc2111', physical_path=>"/vol/gc2111", disk_group=>"SYSTEMS_DEVELOPMENT", total_kb=>100, used_kb=>50, filername=>"gpfs-dev");
    Sdm::Disk::Volume->create( mount_path => '/gscmnt/gc2116', physical_path=>"/vol/gc2116", total_kb=>100, used_kb=>90, filername=>"gpfs-dev");
    Sdm::Disk::Volume->create( mount_path => '/gscmnt/gpfsdev2', physical_path=>"/vol/gpfsdev2", disk_group=>"SYSTEMS_DEVELOPMENT", total_kb=>100, used_kb=>50, filername=>"gpfs-dev");
    Sdm::Disk::Volume->create( mount_path => '/gscmnt/gc2112', physical_path=>"/vol/gc2112", disk_group=>"SYSTEMS_DEVELOPMENT", total_kb=>100, used_kb=>90, filername=>"gpfs");
    Sdm::Disk::Volume->create( mount_path => '/gscmnt/gc2113', physical_path=>"/vol/gc2113", disk_group=>"SYSTEMS_DEVELOPMENT", total_kb=>100, used_kb=>90, filername=>"gpfs2");
    Sdm::Disk::Volume->create( mount_path => '/gscmnt/gc2114', physical_path=>"/vol/gc2114", disk_group=>"SYSTEMS", total_kb=>100, used_kb=>90, filername=>"gpfs2");
    Sdm::Disk::Volume->create( mount_path => '/gscmnt/gc2115', physical_path=>"/vol/gc2115", disk_group=>"INFO_APIPE", total_kb=>100, used_kb=>90, filername=>"gpfs2");
    # parent for filesets
    my $volume = Sdm::Disk::Volume->create( mount_path => '/gscmnt/aggr0', physical_path=>"/vol/aggr0", filername=>"gpfs");

    # Disk Sets
    my $diskset1 = Sdm::Disk::ArrayDiskSet->create( arrayname => 'nsams2k1', disk_type => 'sata', disk_num => 192, disk_size => 1833 * 1024 * 1024 );
    my $diskset2 = Sdm::Disk::ArrayDiskSet->create( arrayname => 'nsams2k1', disk_type => 'sas', disk_num => 228, disk_size => 536 * 1024 * 1024 );

    # Fileset
    my $fileset = Sdm::Disk::Fileset->create(
         filername => 'gpfs',
         parent_volume_id => $volume->id,
         physical_path => '/vol/aggr0/gc7000',
         mount_path => '/gscmnt/aggr0/gc7000',
         disk_group => 'INFO_GENOME_MODELS',
         kb_size => 62210072304,
         kb_quota => 0,
         kb_limit => 214748364800,
         kb_in_doubt => 27967088,
         kb_grace => 'none',
         files => 214324,
         file_quota => 0,
         file_limit => 0,
         file_in_doubt => 138,
         file_grace => 'none',
         file_entrytype => 'e'
    );

    UR::Context->commit();
    return 0;
}

1;

