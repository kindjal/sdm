
package System::Service::WebApp::CGI;

use Web::Simple 'System::Service::WebApp::CGI';
use System;

dispatch {

    sub () {
        my ($self,$args) = @_;

        # Find and load a class based on the requested cgi
        # eg. /viewajax/system/disk/volume/table.html.cgi
        # -> System::Disk::Volume::View::Table::Cgi
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
        my $app = $class->new();
        my $content = $app->run($args);

        return [
                200,
                [ 'Content-type', 'text/json' ],
                [$content],
            ];
        }

};

System::Service::WebApp::CGI->run_if_script;
