package SDM::DataSource::Rtm;
use strict;
use warnings;
use SDM;

class SDM::DataSource::Rtm {
    is => [ 'UR::DataSource::MySQL', 'UR::Singleton' ],
};

sub driver { 'mysql' };

sub server { 'database=cacti:host=rtm.gsc.wustl.edu' };

sub login { 'lims' };
sub auth { 'bAhd91Bar0' };

1;
