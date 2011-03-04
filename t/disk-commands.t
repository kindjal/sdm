
use strict;
use warnings;
use Log::Log4perl qw/:levels/;

use above "System";

use Test::More tests => 3;
use Test::Exception;
use Test::Output;

my $o;
my $filername = 'nfs11x';
my $filer = System::Disk::Filer->get( name => $filername );
$filer->delete() if (defined $filer);

lives_ok { System::Disk::Filer->create( name => $filername ); } "create ok";
stderr_like { System::Disk::Filer->create( name => $filername ); } qr/ERROR/, "duplicate prevented ok";
lives_ok { $o = System::Disk::Filer->get( name => $filername ); } "get ok";
lives_ok { $o->status( 1 ); } "update ok";
lives_ok { $o->delete( name => $filername ); } "delete ok";
lives_ok { System::Disk::Filer->create( name => $filername ); } "create again ok";

my $hostname = 'nfs11x';
my $host = System::Disk::Host->get( hostname => $hostname );
$host->delete() if (defined $host);

lives_ok { $o = System::Disk::Host->create( hostname => $hostname ); } "partial create ok";
stderr_like { UR::Context->commit(); } qr/ERROR/, "commit partial create fails ok";
$o->delete();
lives_ok { $o = System::Disk::Host->create( hostname => $hostname, filername => $filername ); } "full create ok";
lives_ok { $o = System::Disk::Host->get( hostname => $hostname ); } "get ok";
lives_ok { $o->status( 1 ); } "update ok";
lives_ok { $o->delete( hostname => $hostname ); } "delete ok";

my $arrayname = 'gceva1';
my $array = System::Disk::Array->get( name => $arrayname );
$array->delete() if (defined $array);

lives_ok { $o = System::Disk::Array->create( name => $arrayname ); } "partial create ok";
stderr_like { UR::Context->commit(); } qr/ERROR/, "commit partial create fails ok";
$o->delete();
lives_ok { $o = System::Disk::Array->create( name => $arrayname, hostname => $hostname ); } "full create ok";
lives_ok { $o = System::Disk::Array->get( name => $arrayname ); } "get ok";
lives_ok { $o->size( 1 ); } "update ok";
lives_ok { $o->delete( name => $arrayname ); } "delete ok";

my $physical_path = '/vol/sata820';
my $mount_path = '/gscmnt/sata820';
my $total_kb = 1;
my $used_kb = 1;
my $volume = System::Disk::Volume->get( physical_path => $physical_path, filername => $filername );
$volume->delete() if (defined $volume);
lives_ok { UR::Context->commit(); } "commit ok";

ok( ! defined System::Disk::Volume->create( physical_path => $physical_path), "partial create returns undef ok");
lives_ok { $o = System::Disk::Volume->create( physical_path => $physical_path, filername => $filername ); } "full create ok";
lives_ok { $o = System::Disk::Volume->get( physical_path => $physical_path ); } "get ok";
lives_ok { $o->total_kb( 2 ); } "update ok";
lives_ok { $o->delete(); } "delete ok";

my $name = "FOO_GROUP";
my $permissions = 2755;
my $sticky = 1;
my $subdirectory = "foo";
my $unix_uid = 1;
my $unix_gid = 1;

my $group = System::Disk::Group->get( name => $name );
$group->delete() if (defined $group);
lives_ok { UR::Context->commit(); } "commit ok";
lives_ok { $o = System::Disk::Group->create( name => $name ); } "partial create returns ok";
stderr_like { UR::Context->commit(); } qr/ERROR/, "commit partial create fails ok";
lives_ok { $o->delete(); } "delete ok";
lives_ok { $o = System::Disk::Group->create( name => $name, permissions => $permissions, sticky => $sticky, subdirectory => $subdirectory, unix_uid => $unix_uid, unix_gid => $unix_gid ); } "full create ok";
lives_ok { $o = System::Disk::Group->get( name => $name ); } "get ok";
lives_ok { $o->sticky( 0 ); } "update ok";
lives_ok { $o->delete(); } "delete ok";
