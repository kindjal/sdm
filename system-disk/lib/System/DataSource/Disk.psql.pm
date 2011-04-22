
package System::DataSource::Disk;
use strict;
use warnings;
use System;

class System::DataSource::Disk {
    is => [ 'UR::DataSource::Pg' ],
};

sub driver { "Pg"; }
sub server { "dbname=system"; }

sub owner  { 'public'; }
sub login  { 'system'; }
sub auth   { 'test'; }

# By default UR RDBMS.pm returns true, which is not what Pg wants
sub _sql_like_supports_escape {
    return 0;
}

1;
