
package SDM::Service::WebApp::Starman;

use strict;
use warnings;

use SDM::Service::WebApp::Starman::Server;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub run {
    my($self, $app) = @_;

    # Not sure this works here
    if ($ENV{SERVER_STARTER_PORT}) {
        require Net::Server::SS::PreFork;
        @Starman::Server::ISA = qw(Net::Server::SS::PreFork); # Yikes.
    }

    # This is really all we care about, that we use our Starman/Server.pm
    SDM::Service::WebApp::Starman::Server->new->run($app, {%$self});
}

1;
