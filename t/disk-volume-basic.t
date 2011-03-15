
use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl qw/:levels/;

use above "System";

use Test::More;
use Test::Exception;

my $res;
my $params;

system('bash ./t/00-disk-prep-test-database.sh');
ok($? >> 8 == 0, "prep test db ok");

$params = { mount_path => '/gscmnt/sata800' };
$res = System::Disk::Volume->create( $params );
ok( defined $res->__errors__, "properly fail to create volume with no filer or path");
$res->delete();

# move to a separate test so we don't have to rollback commit().
# This should fail, because nfs12 isn't in disk_filer table yet.
#$params = { filername => 'nfs12', physical_path => '/vol/sata800' };
#$res = System::Disk::Filerpath->create( $params );
#$res = UR::Context->commit();
#ok( ! defined $res, "properly aborted on fk constraint");

$params = { name => 'nfs11' };
$res = System::Disk::Filer->get_or_create( $params );
$res->delete();
$res = System::Disk::Filer->create( $params );
ok( ! $res->__errors__, "properly create filer");

$params = { name => 'nfs12' };
$res = System::Disk::Filer->get_or_create( $params );
$res->delete();
$res = System::Disk::Filer->create( $params );
ok( ! $res->__errors__, "properly create filer");

$params = { filername => 'nfs11', mount_path => '/gscmnt/sata800' };
$res = System::Disk::Filerpath->get_or_create( $params );
#$res->delete();
#$res = System::Disk::Filerpath->create( $params );
#ok( ! $res->__errors__, "properly create filerpath");
#$res = System::Disk::Filerpath->create( $params );
#ok( ! defined $res, "properly fail on duplicate filerpath");
#$res = System::Disk::Filerpath->create( filername => 'nfs11', mount_path => '/gscmnt/sata801' );
#ok( ! $res->__errors__, "properly create filerpath");
#$res = System::Disk::Filerpath->create( filername => 'nfs11', mount_path => '/gscmnt/sata802' );
#ok( ! $res->__errors__, "properly create filerpath");
#$res = System::Disk::Filerpath->create( filername => 'nfs11', mount_path => '/gscmnt/sata803' );
#ok( ! $res->__errors__, "properly create filerpath");
#UR::Context->commit();

my $fp = System::Disk::Filerpath->get( "nfs11\t/gscmnt/sata800" );
ok ( defined $fp, "filerpath get ok" );
$params = { mount_path => '/gscmnt/sata800', filerpaths => [ $fp ] };
#$params = { mount_path => '/gscmnt/sata800', filerpaths => [ "nfs11\t/gscmnt/sata800" ] };
$res = System::Disk::Volume->create( $params );
ok( ! $res->__errors__, "properly create volume");
UR::Context->commit();

done_testing();
