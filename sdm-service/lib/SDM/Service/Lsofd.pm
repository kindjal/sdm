
package SDM::Service::Lsofd;

use strict;
use warnings;

use SDM;

use HTTP::Daemon;
use HTTP::Status;

$Data::Dumper::Indent = 1;

class SDM::Service::Lsofd {
    is  => 'SDM::Command::Base',
    has => [
        port => {
            is    => 'Number',
            default_value => 10001,
            doc   => 'tcp port'
        },
    ],
};

sub execute {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " execute");

    my $d = HTTP::Daemon->new( LocalPort => $self->port ) or die "failed to create new http daemon: $!";

    $self->logger->info("Listening contact me at: <URL:", $d->url, ">");
    while (my $c = $d->accept) {
        while (my $r = $c->get_request) {
            if ($r->method eq 'POST') {
                print "" . Data::Dumper::Dumper $r->content;
            } else {
                $c->send_error(RC_FORBIDDEN)
            }
        }
        $c->close;
        undef($c);
    }

    return 1;
}

sub help_brief {
    return 'launch lsof daemon';
}

1;
