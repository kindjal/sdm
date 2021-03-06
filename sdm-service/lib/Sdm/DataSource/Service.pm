
package Sdm::DataSource::Service;

use strict;
use warnings;

use Sdm;

BEGIN {
    unless ($ENV{SDM_DATABASE_DRIVER}) {
        $ENV{SDM_DATABASE_DRIVER} = "SQLite";
    }
    unless ($ENV{SDM_DATABASE_HOSTNAME}) {
        $ENV{SDM_DATABASE_HOSTNAME} = "localhost";
    }
};

my $hostname = $ENV{SDM_DATABASE_HOSTNAME};

if ($ENV{SDM_DATABASE_DRIVER} eq "SQLite") {
    class Sdm::DataSource::Service {
        is => [ 'UR::DataSource::SQLite', 'UR::Singleton' ],
        has_constant => [
            driver => { default_value => 'SQLite' },
            dump_on_commit => { default_value => 0 },
        ]
    };
} elsif ($ENV{SDM_DATABASE_DRIVER} eq "Pg") {
    class Sdm::DataSource::Service {
        is => [ 'UR::DataSource::Pg' ],
        has_constant => [
            server => { default_value => "dbname=sdm;host=$hostname" },
            owner  => { default_value => 'public' },
            login  => { default_value => 'sdm' },
            auth   => { default_value => 'pYKVikFf' },
        ]
    };
} elsif ($ENV{SDM_DATABASE_DRIVER} eq "Oracle") {
    class Sdm::DataSource::Service {
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
    if ($ENV{SDM_DATABASE_DRIVER} eq "SQLite") {
        # Setting autocommit makes >1 workers work when long running.
        $dbh->{AutoCommit} = 1;
        $dbh->do("PRAGMA foreign_keys = ON");
    }
    return $dbh;
}

sub _sql_like_supports_escape {
    # By default UR RDBMS.pm returns true, which is not what Pg wants
    if ($ENV{SDM_DATABASE_DRIVER} eq "Pg") {
        return 0;
    }
    return 1;
}

sub _sql_like_wants_cast {
    if ($ENV{SDM_DATABASE_DRIVER} eq "Pg") {
        return 'VARCHAR';
    }
}

1;
