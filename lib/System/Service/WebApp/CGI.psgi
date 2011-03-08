#!/usr/bin/perl

use Web::Simple 'System::Service::WebApp::CGI';
use File::Basename qw/basename/;

package System::Service::WebApp::CGI;

dispatch {

    sub () {
        my ($self,$args) = @_;

        # Find and load a class based on the requested cgi
        my $class = $args->{PATH_INFO};
        $class = File::Basename::basename($class);
        $class =~ s/^\///g;
        $class = ucfirst($class);
        $class = "System::View::Resource::Html::Cgi::$class";
        eval "require $class";

        my $app = $class->new();
        my $content = $app->run();

        return [
                200,
                [ 'Content-type', 'text/plain' ],
                [$content],
            ];
        }

};

System::Service::WebApp::CGI->run_if_script;
