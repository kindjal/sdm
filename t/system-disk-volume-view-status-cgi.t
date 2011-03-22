
use strict;
use warnings;
use Data::Dumper;

use above "System";

use Test::More;
use Test::Output;
use Test::Exception;

use System::Disk::Volume::View::Status::Cgi;
use URI;

my $q;
my $o;
my $r;
my $uri;

system("bash ./t/00-disk-prep-test-database.sh");
ok( $? >> 8 == 0, "DB prep ok");

$uri = "/site/system/disk/volume/status.html.cgi?sEcho=11&iColumns=7&sColumns=&iDisplayStart=0&iDisplayLength=25&sSearch=APIPE&bEscapeRegex=true&sSearch_0=&bEscapeRegex_0=true&bSearchable_0=true&sSearch_1=&bEscapeRegex_1=true&bSearchable_1=true&sSearch_2=&bEscapeRegex_2=true&bSearchable_2=true&sSearch_3=&bEscapeRegex_3=true&bSearchable_3=true&sSearch_4=&bEscapeRegex_4=true&bSearchable_4=true&sSearch_5=&bEscapeRegex_5=true&bSearchable_5=true&sSearch_6=&bEscapeRegex_6=true&bSearchable_6=true&iSortingCols=1&iSortCol_0=2&sSortDir_0=desc&bSortable_0=true&bSortable_1=true&bSortable_2=true&bSortable_3=true&bSortable_4=true&bSortable_5=true&bSortable_6=true&rm=table_data HTTP/1.1";

$q = URI->new($uri);
$o = System::Disk::Volume::View::Status::Cgi->new();
$r = $o->_build_result_set($q);

print Dumper $r;

done_testing();
