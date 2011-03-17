
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
ok( $v = System::Disk::Volume->get_or_create( filername => 'nfs11', mount_path => '/gscmnt/sata821', physical_path => '/vol/sata821' ), "get_or_create volume ok");
ok( UR::Context->commit(), "commit ok");
done_testing();
