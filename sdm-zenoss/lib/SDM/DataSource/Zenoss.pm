
package SDM::DataSource::Zenoss;

use strict;
use warnings;

use SDM;

my $hostname = $ENV{SDM_ZENOSS_DATABASE_HOSTNAME};

if ($ENV{SDM_ZENOSS_DATABASE_DRIVER} eq "SQLite") {
    class SDM::DataSource::Zenoss {
        is => [ 'UR::DataSource::SQLite', 'UR::Singleton' ],
        has_constant => [
            driver => { default_value => 'SQLite' },
            dump_on_commit => { default_value => 0 },
        ]
    };
} elsif ($ENV{SDM_ZENOSS_DATABASE_DRIVER} eq "MySQL") {
    class SDM::DataSource::Zenoss {
        is => [ 'UR::DataSource::MySQL' ],
        has_constant => [
            server => { default_value => "dbname=events;host=$hostname" },
            owner  => { default_value => 'public' },
            login  => { default_value => 'sdm' },
            auth   => { default_value => 'pYKVikFf' },
        ]
    };
}

sub create_dbh {
    # Need to manually enable foreign key constraints in sqlite
    my $self = shift->_singleton_object();
    my $dbh = $self->SUPER::create_dbh(@_);
    if ($ENV{SDM_ZENOSS_DATABASE_DRIVER} eq "SQLite") {
        $dbh->do("PRAGMA foreign_keys = ON");
    }
    return $dbh;
}

1;
