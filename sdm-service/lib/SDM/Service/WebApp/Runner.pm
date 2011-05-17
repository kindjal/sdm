
package SDM::Service::WebApp::Runner;

use base qw( Plack::Runner );
use SDM::Service::WebApp::Starman;

sub load_server {
    my($self, $loader) = @_;
    $self->{server}->new(@{$self->{options}});
}

1;
