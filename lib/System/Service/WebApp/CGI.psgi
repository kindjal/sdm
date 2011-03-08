#!/usr/bin/perl

use Web::Simple 'System::Service::WebApp::CGI';

package System::Service::WebApp::CGI;

dispatch {

    sub () {
        my ($self,$args) = @_;
        print "DEBUG:" . Data::Dumper::Dumper $args;

        # Find a load a class based on the requested cgi
        my $class = $args->{PATH_INFO};
        $class =~ s/^\///g;
        $class = "System::View::Resource::Html::Cgi::$class";
        my $mod = $class;
        $mod =~ s/::/\//g;
        $mod .= ".pm";
        require "$mod";

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
