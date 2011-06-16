
package SDM::Service::Lsofd::Command::Run;

class SDM::Service::Lsofd::Command::Run {
    is => 'SDM::Command::Base',
};

sub execute {
    my $self = shift;
    eval {
        $app = SDM::Service::Lsofd->create();
        $app->loglevel( $self->loglevel );
        $app->execute();
    };
    if ($@) {
        die "Failed during execute(): $@";
    }
}

1;
