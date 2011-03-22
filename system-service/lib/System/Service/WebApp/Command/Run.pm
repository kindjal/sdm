
package System::Service::WebApp::Command::Run;

class System::Service::WebApp::Command::Run {
    is => 'System::Command::Base'
};

sub execute {
  my $self = shift;
  eval {
     $app = System::Service::WebApp->create();
     $app->execute();
  };
  if ($@) {
    die "Failed during execute(): $@";
  }
}

1;
