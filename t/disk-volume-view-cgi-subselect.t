
use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl qw/:levels/;

use above "System";

use Test::More tests => 1;
use Test::Exception;

#use System::Disk::Volume::View::Table::Cgi;
#use URI;

my @result = System::Disk::Volume->get( total_kb => { operator => 'sum' } );
print Data::Dumper::Dumper @result;

