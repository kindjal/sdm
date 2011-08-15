
package SDM::Zenoss::API;

use SDM;
use Zenoss;

use strict;
use warnings;

class SDM::Zenoss::API {
    is => 'SDM::Command::Base',
    has => [
        connection => { is => 'Zenoss' },
        username   => { is => 'Text', default_value => 'restuser' },
        password   => { is => 'Text', default_value => 'Poh0quoh' },
        url        => { is => 'Text', default_value => 'http://monitor.gsc.wustl.edu:8080/' },
    ]
};

sub connect {
    my $self = shift;
    my $api = Zenoss->connect(
        {
            username    => $self->{username},
            password    => $self->{password},
            url         => $self->{url},
        }
    );
    $self->connection( $api );
    return 1;
}

sub create {
    my $self = shift;
    my $obj = $self->SUPER::create();
    $obj->connect;
    return $obj;
};

1;
