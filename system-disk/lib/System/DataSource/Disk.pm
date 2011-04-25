
package System::DataSource::Disk;

use strict;
use warnings;

use System;

BEGIN {
    unless ($ENV{SYSTEM_DATABASE_DRIVER}) {
        $ENV{SYSTEM_DATABASE_DRIVER} = "SQLite";
    }
    unless ($ENV{SYSTEM_DATABASE_HOSTNAME}) {
        $ENV{SYSTEM_DATABASE_HOSTNAME} = "localhost";
    }
};

my $hostname = $ENV{SYSTEM_DATABASE_HOSTNAME};

if ($ENV{SYSTEM_DATABASE_DRIVER} eq "SQLite") {
    class System::DataSource::Disk {
        is => [ 'UR::DataSource::SQLite', 'UR::Singleton' ],
        has_constant => [
            driver => { default_value => 'SQLite' },
            dump_on_commit => { default_value => 1 },
        ]
    };
} elsif ($ENV{SYSTEM_DATABASE_DRIVER} eq "Pg") {
    class System::DataSource::Disk {
        is => [ 'UR::DataSource::Pg' ],
        has_constant => [
            server => { default_value => "dbname=system;host=$hostname" },
            owner  => { default_value => 'public' },
            login  => { default_value => 'system' },
            auth   => { default_value => 'test' },
        ]
    };
} elsif ($ENV{SYSTEM_DATABASE_DRIVER} eq "Oracle") {
    class System::DataSource::Disk {
        is => [ 'UR::DataSource::Oracle' ],
        has_constant => [
            driver => { default_value => 'Oracle' },
            server => { default_value => 'gcdev' },
            owner  => { default_value => 'infosys' },
            login  => { default_value => 'infosys' },
            auth   => { default_value => 'pYKVikFf' },
        ]
    };
}

sub create_dbh {
    # Need to manually enable foreign key constraints in sqlite
    my $self = shift->_singleton_object();
    my $dbh = $self->SUPER::create_dbh(@_);
    if ($ENV{SYSTEM_DATABASE_DRIVER} eq "SQLite") {
        $dbh->do("PRAGMA foreign_keys = ON");
    }
    return $dbh;
}

sub _sql_like_supports_escape {
    # By default UR RDBMS.pm returns true, which is not what Pg wants
    if ($ENV{SYSTEM_DATABASE_DRIVER} eq "Pg") {
        return 0;
    }
    return 1;
}

sub _sql_like_wants_cast {
    if ($ENV{SYSTEM_DATABASE_DRIVER} eq "Pg") {
        return 'VARCHAR';
    }
}

1;
