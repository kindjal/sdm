package Sdm::DataSource::Rtm;
use strict;
use warnings;
use Sdm;

my $hostname = $ENV{SDM_RTM_HOSTNAME};

class Sdm::DataSource::Rtm {
    is => [ 'UR::DataSource::MySQL', 'UR::Singleton' ],
    has_constant => [
        server => { default_value => "database=cacti:host=$hostname" },
        owner  => { default_value => 'lims' },
        login  => { default_value => 'lims' },
        auth   => { default_value => 'bAhd91Bar0' },
    ]
};

1;
