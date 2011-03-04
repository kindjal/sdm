
use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl qw/:levels/;

use above "System";

use Test::More tests => 1;
use Test::Exception;

my $volume = System::Disk::Volume->create(
  'physical_path' => '/vol/sata812',
  'filername' => 'nfs11',
  'total_kb' => 6438990688,
  'disk_group' => 'PRODUCTION_SOLID',
  'mount_path' => '/gscmnt/sata812',
  'used_kb' => 5722964896
);
my $view = $volume->create_view(
  toolkit => 'html',
);
print Dumper $view;
#$view->show();
$view->content();
