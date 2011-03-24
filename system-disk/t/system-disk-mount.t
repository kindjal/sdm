
use strict;
use warnings;

use System;

use Test::More;
use Test::Output;
use Test::Exception;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

my $res;
my $params;

# Start with a fresh database
system('bash ./t/00-disk-prep-test-database.sh');
ok($? >> 8 == 0, "prep test db ok");

# Test insufficient creation params
my @params = ();
ok( ! defined System::Disk::Mount->create( @params ), "properly fail to create mount with empty param" );

# A mount is a mapping between an Export and a Volume

# FIXME below here...
#
# Test creation
@params = ( filername => 'filer', physical_path => '/vol/sata800', mount_path => '/gscmnt/sata800' );
my $volume = System::Disk::Volume->create( @params );
ok( defined $volume->id, "properly created new volume");

@params = ();
$res = System::Disk::Mount->get( @params );
ok( defined $res->id, "properly got new mount");

@params = ( filername => 'filer', physical_path => '/vol/sata801' );
my $export = System::Disk::Export->create( @params );
ok( defined $export->id, "properly made new export");

@params = ( volume_id => $volume->id , export_id => $export->id );
$res = System::Disk::Mount->create( @params );
ok( defined $res->id, "properly made new mount");

# Now test 'delete'
foreach $res ( System::Disk::Mount->get() ) {
    $res->delete();
    isa_ok( $res, 'UR::DeletedRef' );
}

done_testing();