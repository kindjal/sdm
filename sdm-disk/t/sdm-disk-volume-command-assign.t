
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} = "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

use Sdm;

use File::Path;

use Test::More;
use Test::Output;
use Test::Exception;

BEGIN {
    # use commit to make sure we really test writes to DB
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

my $res;
my $params;

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";
ok( Sdm::Disk::Lib->testinit == 0, "ok: init db");

# Create filer and group to test with
my $filer = Sdm::Disk::Filer->create( name => 'localhost' );
ok( defined $filer, "created test filer ok");

my $group = Sdm::Disk::Group->create( name => 'info', permissions => 0755, unix_uid => 12376, unix_gid => 10001, subdirectory => 'info' );
ok( defined $group, "created test group ok");

# Test creation
my $dir = "$top/t/test_volume";
File::Path::rmtree $dir;
mkdir $dir, 0755 or die "Can't make test dir: $dir: $!";
my @params = ( filername => 'localhost', mount_path => $dir, physical_path => $dir );
my $volume = Sdm::Disk::Volume->create( @params );
ok( defined $volume, "properly created new volume");

my $command = Sdm::Disk::Volume::Command::Assign->create( volume => $volume , group => $group );
$res = $command->execute();
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($dir);
$mode = sprintf "%04o", $mode & 07777;
ok( $mode eq '0755', "ok: mode $mode" );
ok( $uid == 12376, "ok: uid $uid" );
ok( $gid == 10001, "ok: gid $gid" );
ok( $volume->disk_group() eq $group->name, "ok: group assigned" );
File::Path::rmtree $dir;

done_testing();

