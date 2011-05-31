package SDM::Service::WebApp;

use strict;
use warnings;

use SDM;
use SDM::Service::WebApp::Starman;
use SDM::Service::WebApp::Runner;
use SDM::Service::WebApp::Loader;
use Workflow;
use Sys::Hostname;
use AnyEvent;
use AnyEvent::Util;
use IO::Socket;

# "Unassigned" ports from iana.org
my @AVAILABLE_PORTS = (8089, 8090, 8092, 8093, 8094, 8095,
                       9096, 8098, 8099, 8102, 8103, 8104,
                       8105, 8106, 8107, 8108, 8109, 8110,
                       8111, 8112, 8113, 8114);

class SDM::Service::WebApp {
    #is  => 'SDM::Command::Base',
    has => [
        browser => {
            ## this property has its accessor overriden to provide defaults
            is  => 'String',
            doc => 'command to run to launch the browser'
        },
        port => {
            is    => 'Number',
            default_value => '8090',
            doc   => 'tcp port for internal server to listen'
        },
        fixed_port => {
            is    => 'Boolean',
            default_value => 0,
            doc   => 'force the use of the same port',
        }
    ],
};

sub execute {
    my $self = shift;
    $self->determine_port;
    $self->status_message( sprintf( "Using browser: %s", $self->browser ) );
    $self->status_message( sprintf( "Local server accessible at %s", $self->url ) );
    $self->fork_and_call_browser
      if ( $ENV{DISPLAY} && !( $ENV{SSH_CLIENT} || $ENV{SSH_CONNECTION} ) );
    $self->run_starman;
}

sub fork_and_call_browser {
    my ($self) = @_;

    my $command = [ $self->browser, $self->url ];

    run_cmd $command,
      '>'        => \*STDOUT,
      '2>'       => \*STDERR,
      close_all  => 1,
      on_prepare => sub {
        sleep 2;
      }
}

sub psgi_path {
    my $self = shift;
    my $module_path = $self->__meta__->module_path;
    $module_path =~ s/\.pm$//g;
    return $module_path;
}

sub res_path {
    $_[0]->psgi_path . '/resource';
}

sub determine_port {
    my ($self) = @_;
    return if ($self->fixed_port);
    unshift ( @AVAILABLE_PORTS, $self->port );
    $self->port(undef);
    foreach ( @AVAILABLE_PORTS ) {
        $self->status_message( sprintf ( "Checking port %d to ensure it is unused.\n", $_ ) );
        my $open_socket = IO::Socket::INET->new(
            LocalAddr => 'localhost',
            LocalPort => $_,
            Proto => 'tcp'
        );
        if ( defined $open_socket ) {
            $open_socket->close();
            $self->port($_);
            $self->status_message( sprintf( "Selected port: %d\n", $self->port ) );
            last;
        }
        $self->status_message( sprintf( "Port %d in use. Trying next choice.\n", $_) );
    }
    die "None of the offered ports are available. Add more ports to SDM::Model::Command::Service::WebApp or specify a different port." unless ( $self->port );
}

sub run_starman {
    my ($self) = @_;

    my $runner = SDM::Service::WebApp::Runner->new(
        server => 'SDM::Service::WebApp::Starman',
        loader => 'SDM::Service::WebApp::Loader',
        env    => 'development',
    );

    my $psgi_path = $self->psgi_path . '/Main.psgi';

    $runner->parse_options(
        '--app', $psgi_path,
        '--port', $self->port,
        '--workers', 4,
        '--single_request', 1,
        '-R', SDM->base_dir );

    $runner->run;
}

sub browser {
    my $self = shift;

    return $self->__browser(@_) if (@_);

    my $b = $self->__browser;
    return $b if ( defined $b );

    if ( exists $ENV{BROWSER} && defined $ENV{BROWSER} ) {
        return $self->__browser( $ENV{BROWSER} );
    }

    return $self->__browser('firefox');
}

sub help_brief {
    return 'launch single user web app';
}

sub is_sub_command_delegator {
    return;
}

sub url {
    my $self = shift;
    my $hostname = Sys::Hostname::hostname;
    my $url = sprintf ( "http://%s:%d/", $hostname, $self->port );
    return $url;
}

1;