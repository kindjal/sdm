
use strict;
use warnings;

BEGIN {
    $ENV{SYSTEM_DEPLOYMENT} ||= "testing";
    $ENV{SYSTEM_LOGLEVEL} ||= "DEBUG";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

use Test::More;
use Test::Output;
use Test::Exception;

use_ok( "System" );
use_ok( "System::Disk::GpfsDiskPerf" );

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/system-lib.pm";
ok( System::Test::Lib->testinit == 0, "ok: init db");
ok( System::Test::Lib->testdata == 0, "ok: init db");

my @params = ( filername => 'gpfs-dev', physical_path => '/vol/gpfsdev13', mount_path => '/gscmnt/gpfsdev13' );
ok( my $vol = System::Disk::Volume->create( @params ), "ok: create test volume");

# Test insufficient creation params
@params = ();
ok( ! defined System::Disk::GpfsDiskPerf->create( @params ), "ok: create fails on empty params");

@params = ( gpfsFileSystemPerfName => "/gscmnt/gc2111" );
ok( ! defined System::Disk::GpfsDiskPerf->create( @params ), "ok: create fails on insufficient params");

my %params = (
  volume_id => $vol->id,
  gpfsDiskLongestReadTimeL => '19455',
  gpfsDiskLongestReadTimeH => '0',
  gpfsDiskReadTimeL => '461932',
  gpfsDiskWriteOps => '0',
  gpfsDiskShortestWriteTimeH => '0',
  gpfsDiskWriteTimeL => '0',
  gpfsDiskPerfName => 'ams2k6lun000e',
  gpfsDiskReadOps => '1294',
  gpfsDiskReadTimeH => '0',
  gpfsDiskShortestWriteTimeL => '0',
  gpfsDiskWriteBytesH => '0',
  gpfsDiskReadBytesL => '10590208',
  gpfsDiskShortestReadTimeH => '0',
  gpfsDiskPerfStgPoolName => 'system',
  gpfsDiskWriteBytesL => '0',
  gpfsDiskReadBytesH => '0',
  gpfsDiskPerfFSName => '/vol/gpfsdev13',
  gpfsDiskLongestWriteTimeL => '0',
  gpfsDiskShortestReadTimeL => '0',
  gpfsDiskWriteTimeH => '0',
  gpfsDiskLongestWriteTimeH => '0'
);
ok( defined System::Disk::GpfsDiskPerf->create( %params ), "ok: create works");
ok( defined UR::Context->commit, "ok: commit succeeds" );
$params{gpfsDiskPerfName} = 'ams2k6lun000f';
ok( defined System::Disk::GpfsDiskPerf->create( %params ), "ok: create works");

foreach my $ref ( System::Disk::GpfsDiskPerf->get() ) {
    $ref->delete();
    isa_ok( $ref, 'UR::DeletedRef' );
}
UR::Context->commit();
done_testing();
