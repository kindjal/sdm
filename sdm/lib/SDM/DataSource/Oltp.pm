package SDM::DataSource::Oltp;

use strict;
use warnings;
use SDM;

class SDM::DataSource::Oltp {
    is => 'UR::DataSource::Oracle',
    type_name => 'genome datasource oltp',
};

sub server {
    'gscprod';
}

sub login {
    'gscuser';
}

sub auth {
    'g_user';
}

sub owner {
    'gsc';
}


1;

