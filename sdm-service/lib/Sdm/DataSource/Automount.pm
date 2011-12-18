
package Sdm::DataSource::Automount;

use strict;
use warnings;

use Sdm;

class Sdm::DataSource::Automount {
    is => [ 'UR::DataSource::SQLite', 'UR::Singleton' ],
    has => [
        filename => { is => 'Text' }
    ],
    has_constant => [
        driver => { default_value => 'SQLite' },
        dump_on_commit => { default_value => 1 },
    ]
};

sub create_dbh {
    # Need to manually enable foreign key constraints in sqlite
    my $self = shift->_singleton_object();
    my $dbh = $self->SUPER::create_dbh(@_);
    $dbh->do("PRAGMA foreign_keys = ON");
    return $dbh;
}

sub server {
    my $self = shift->_singleton_object();
    return $self->filename if ($self->filename);
    my $path = $self->__meta__->module_path;
    my $ext = $self->_extension_for_db;
    $path =~ s/\.pm$/$ext/ or Carp::confess("Odd module path $path");
    return $path;
}

1;
