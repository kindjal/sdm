
package System::Service::WebApp::CGI;

use Web::Simple 'System::Service::WebApp::CGI';
use System;
use JSON;

dispatch {

    sub () {
        my ($self,$args) = @_;

        # Find and load a class based on the requested cgi
        # eg. /viewajax/system/disk/volume/summary.html.cgi
        # -> System::Disk::Volume::View::Summary::Cgi
        my $class = $args->{PATH_INFO};
        my @parts = split('/',$class);
        my $perspective = ucfirst($parts[$#parts]);
        $perspective =~ /^(\S+)\.\S+$/;
        $perspective = $1;
        @parts = @parts[2..$#parts-1];
        @parts = map { ucfirst } @parts;
        $class = join('::',@parts);
        $class .= "::View::${perspective}::Cgi";

        eval "require $class";
        my $loglevel = $ENV{SYSTEM_LOGLEVEL};
        my $app;
        if ($loglevel) {
            $app = $class->create( loglevel => $loglevel );
        } else {
            $app = $class->create();
        }
        my $content;
        eval {
            $content = $app->run( $args->{REQUEST_URI} );
        };
        if ($@) {
            my $json = JSON->new();
            my $error = {
                'iTotalRecords' => 1,
                'iTotalDisplayRecords' => 1,
                'aaData' => [ [ 'ERROR', $@, '', '' ], ],
                'sEcho' => 1
            };
            $content = $json->encode($error);
            return [
                500,
                [ 'Content-type', 'text/json' ],
                [$content],
               ];
        }

        return [
                200,
                [ 'Content-type', 'text/json' ],
                [$content],
               ];
        }

};

System::Service::WebApp::CGI->run_if_script;
