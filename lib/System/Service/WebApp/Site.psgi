#!/usr/bin/perl

use Web::Simple 'System::Service::WebApp::Site';

package System::Service::WebApp::Site;

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
        @parts = @parts[1..$#parts-1];
        @parts = map { ucfirst } @parts;
        $class = join('::',@parts);
        $class .= "::View::${perspective}::Html";

        eval "require $class";
        if ($@) {
            return [
                404,
                [ 'Content-type', 'text/html' ],
                [ "No class found: $class" ],
            ];
        }

        my $content;
        eval {
            my $app = $class->new();
            $content = $app->_generate_content($args);
        };
        if ($@) {
            return [
                404,
                [ 'Content-type', 'text/html' ],
                [ "Error loading content generator: $@" ],
            ];
        }

        return [
                200,
                [ 'Content-type', 'text/html' ],
                [$content],
               ];
        }

};

System::Service::WebApp::Site->run_if_script;
