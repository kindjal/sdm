package System::DataSource::Disk;
use strict;
use warnings;
use System;

class System::DataSource::Disk {
    #is => [ 'UR::DataSource::SQLite', 'UR::Singleton' ],
    is => [ 'UR::DataSource::Pg' ],
};

#sub driver { 'SQLite' };
#sub dump_on_commit { 1 };

sub driver { "Pg"; }
sub server { "dbname=system"; }

sub owner  { 'public'; }
sub login  { 'system'; }
sub auth   { 'test'; }

#sub create_dbh {
#    my $self = shift->_singleton_object();
#    $self->_init_database;
#    my $dbh = $self->SUPER::create_dbh(@_);
#    $dbh->do("PRAGMA foreign_keys = ON");
#    return $dbh;
#}

1;
