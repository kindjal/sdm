
use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl qw/:levels/;

use above "System";

use Test::More tests => 1;
use Test::Exception;

use Date::Manip;

my $volume = System::Disk::Volume->get( filername => 'nfs11', physical_path => "/vol/sata821" );
$volume->add_observer( callback => sub {
    $volume->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
} );
$volume->total_kb( 7438990688 );

my $c = $volume->created;
my $m = $volume->last_modified;
$c =~ s/[- ]/:/g;
$m =~ s/[- ]/:/g;
my $err;
my $date0 = ParseDate($c);
my $date1 = ParseDate($m);
my $calc  = DateCalc($date0,$date1,\$err);
my $delta = Delta_Format($calc,0,'%st');
ok( $delta > 1, "last_modified gets updated");

#my $db = System->base_dir . 'DataSource/Disk.sqlite3n';
#`sqlite3 $db UPDATE disk_volume set last_modified = date('now','-30 days') WHERE filername = 'nfs11' AND physical_path = "/vol/sata821"`;

my $o = System::Disk::Filer::Command::Usage->create( vol_maxage => 1 );
$o->prepare_logger();
$o->{logger}->level($DEBUG);
my @r = $o->fetch_aging_volumes();
print Data::Dumper::Dumper @r;

