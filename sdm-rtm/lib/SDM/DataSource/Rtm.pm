package SDM::DataSource::Rtm;
use strict;
use warnings;
use SDM;

my $hostname = $ENV{SDM_RTM_HOSTNAME};

class SDM::DataSource::Rtm {
    is => [ 'UR::DataSource::MySQL', 'UR::Singleton' ],
    has_constant => [
        server => { default_value => "database=cacti:host=$hostname" },
        owner  => { default_value => 'lims' },
        login  => { default_value => 'lims' },
        auth   => { default_value => 'bAhd91Bar0' },
    ]
};

1;
