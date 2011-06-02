
package SDM::Service::WebApp::Command::Run;

class SDM::Service::WebApp::Command::Run {
    is => 'SDM::Command::Base',
    has_optional => [
        fixed_port => {
            is => Boolean,
            default => 0,
            doc => "force a fixed port, useful in daemon mode",
        },
    ]
};

sub execute {
    my $self = shift;
    eval {
        $app = SDM::Service::WebApp->create( fixed_port => $self->fixed_port );
        $app->execute();
    };
    if ($@) {
        die "Failed during execute(): $@";
    }
}

1;
