
use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl qw/:levels/;

use above "System";

use Test::More tests => 3;
use Test::Exception;

# FIXME:
# This test requires a live network connection to a host nfs11

my $command = System::Disk::Filer::Command::Usage->create();
my $filer = System::Disk::Filer->get( name => 'nfs11' );
$command->prepare_logger();
$command->{logger}->level($DEBUG);

lives_ok { $command->execute($filer); } "usage->execute() runs ok";

UR::Context->commit();

my $volume = System::Disk::Volume->get( filername => 'nfs11', physical_path => '/vol/sata812' );
ok( $volume->mount_path eq '/gscmnt/sata812', "mount_path matches" );
ok( $volume->physical_path eq '/vol/sata812', "physical_path matches" );
