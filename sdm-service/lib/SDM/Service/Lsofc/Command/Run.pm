
package SDM::Service::Lsofc::Command::Run;

class SDM::Service::Lsofc::Command::Run {
    is => 'SDM::Command::Base',
};

sub execute {
    my $self = shift;
    eval {
        $app = SDM::Service::Lsofc->create();
        $app->execute();
    };
    if ($@) {
        die "Failed during execute(): $@";
    }
}

1;
