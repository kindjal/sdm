
use strict;
use warnings;

use above "System";

use Test::More tests => 2;
use Test::Output;
use Test::Exception;
use Log::Log4perl qw/:levels/;

use Data::Dumper;

my $self = shift;
my $obj = System::Disk::Filer::Command::Create->create();

$obj->prepare_logger();
$obj->{logger}->level('DEBUG');

$obj->{logger}->level($DEBUG);
stderr_like { $obj->{logger}->debug("Test") } qr/^.* Test/, "test_logger: debug on ok";

$obj->{logger}->level($WARN);
stderr_isnt { $obj->{logger}->debug("Test") } qr/^.* Test/, "test_logger: debug off ok";
