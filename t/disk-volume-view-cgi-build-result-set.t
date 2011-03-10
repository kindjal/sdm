
use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl qw/:levels/;

use above "System";

use Test::More tests => 1;
use Test::Exception;

use System::Disk::Volume::View::Table::Cgi;
use URI;

sub compare_arrays {
     my ($first, $second) = @_;
     no warnings;  # silence spurious -w undef complaints
         return 0 unless @$first == @$second;
     for (my $i = 0; $i < @$first; $i++) {
         return 0 if $first->[$i] ne $second->[$i];
     }
     return 1;
}

my $uri;
my $query;
my $o;
my $r;
my @vols;
my @expected;
my @keys;

$uri = "/site/system/disk/volume/table.html.cgi?sEcho=13&iColumns=8&sColumns=&iDisplayStart=0&iDisplayLength=25&sSearch=&bEscapeRegex=true&sSearch_0=&bEscapeRegex_0=true&bSearchable_0=true&sSearch_1=&bEscapeRegex_1=true&bSearchable_1=true&sSearch_2=&bEscapeRegex_2=true&bSearchable_2=true&sSearch_3=&bEscapeRegex_3=true&bSearchable_3=true&sSearch_4=&bEscapeRegex_4=true&bSearchable_4=true&sSearch_5=&bEscapeRegex_5=true&bSearchable_5=true&sSearch_6=&bEscapeRegex_6=true&bSearchable_6=true&sSearch_7=&bEscapeRegex_7=true&bSearchable_7=true&iSortingCols=1&iSortCol_0=1&sSortDir_0=desc&bSortable_0=true&bSortable_1=true&bSortable_2=true&bSortable_3=true&bSortable_4=true&bSortable_5=true&bSortable_6=true&bSortable_7=true&rm=table_data HTTP/1.1";

$query = URI->new( $uri );
$o = System::Disk::Volume::View::Table::Cgi->new();
@vols  = $o->_build_result_set($query);
# We will sort by physical path based on uri above, not by id
@expected = ("nfs12\t/vol/gc2000","nfs11\t/vol/sata821");
@keys = map { $_->{id} } @vols;
ok( compare_arrays( \@expected, \@keys ), "result set has 2 items" );

$uri = "/site/system/disk/volume/table.html.cgi?sEcho=13&iColumns=8&sColumns=&iDisplayStart=0&iDisplayLength=25&sSearch=gc2&bEscapeRegex=true&sSearch_0=&bEscapeRegex_0=true&bSearchable_0=true&sSearch_1=&bEscapeRegex_1=true&bSearchable_1=true&sSearch_2=&bEscapeRegex_2=true&bSearchable_2=true&sSearch_3=&bEscapeRegex_3=true&bSearchable_3=true&sSearch_4=&bEscapeRegex_4=true&bSearchable_4=true&sSearch_5=&bEscapeRegex_5=true&bSearchable_5=true&sSearch_6=&bEscapeRegex_6=true&bSearchable_6=true&sSearch_7=&bEscapeRegex_7=true&bSearchable_7=true&iSortingCols=1&iSortCol_0=1&sSortDir_0=desc&bSortable_0=true&bSortable_1=true&bSortable_2=true&bSortable_3=true&bSortable_4=true&bSortable_5=true&bSortable_6=true&bSortable_7=true&rm=table_data HTTP/1.1";
$query = URI->new( $uri );
$o = System::Disk::Volume::View::Table::Cgi->new();
@vols  = $o->_build_result_set($query);
@expected = ( "nfs12\t/vol/gc2000" );
@keys = map { $_->{id} } @vols;
ok( compare_arrays( \@expected, \@keys ), "result set has 1 items" );
