
use strict;
use warnings;

use above "System";

use Test::More;
use Test::Exception;

my $f;
my $e;
my $v;
my $m;

system('bash t/00-disk-prep-test-database.sh');
ok( $? >> 8 == 0, "flush db ok");
ok( $f = System::Disk::Filer->get_or_create( name => 'nfs11' ), "create filer ok");
ok( $e = System::Disk::Export->get_or_create( filername => 'nfs11', physical_path => '/vol/sata821' ), "create export ok");
ok( $v = System::Disk::Volume->_new( mount_path => '/gscmnt/sata821' ), "create volume ok");
ok( $m = System::Disk::Mount->get_or_create( export_id => $e->id, volume_id => $v->id ), "create mount ok");
ok( UR::Context->commit(), "commit ok");
done_testing();
