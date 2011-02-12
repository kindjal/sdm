package System::DataSource::Disk;
use strict;
use warnings;
use System;

class System::DataSource::Disk {
    is => [ 'UR::DataSource::SQLite', 'UR::Singleton' ],
};

sub driver { 'SQLite' };

sub server { 'Disk.sqlite3' };


1;
