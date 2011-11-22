#!/usr/bin/perl

package SDM::Service::WebApp::Main;

use strict;
use warnings;

use SDM;
use Dancer;
use Data::Dumper;
$Data::Dumper::Terse = 1;

use Date::Format qw/time2str/;
use UR::Object::View::Default::Xsl qw/type_to_url url_to_type/;
use Cwd qw/realpath/;

my $appdir = realpath( "$FindBin::Bin/.." );

# Default route handler
get '/' => sub {
    warning "Using default route handler";
    redirect "/view/sdm/search/status.html";
};

# Direct response for HTML resources, .css, .png etc.
get qr{/[^view](.*)} => sub {
    warning "Using static content route handler";
    my ($file) = @{ params->{splat} };
    return send_file($file);
};

post '/service/lsof' => sub {
    return "LSOF not yet implemented";
};

post '/service/add' => sub {
    my $self = shift;
    my $class = delete params->{class};
    # Don't confuse UR, let it come up with the id.
    delete params->{id};
    $class =~ s/::Set$//;
    my $obj;
    eval {
        $obj = $class->create( params );
        unless ($obj) {
            die __PACKAGE__ . " Failed to create object";
        }
        UR::Context->commit();
    };
    if ($@) {
        warning "error: " . Data::Dumper::Dumper $@;
        return send_error();
    }
    warning "returning: " . $obj->id;
    # Send back the ID, which should be used by
    # datatables editable as a new row id
    return $obj->id;
};

post '/service/update' => sub {
    my $self = shift;
    my $msg;
    eval {
        my $attr = params->{columnName};
        my $value = params->{value};
        my $class = params->{class};
        $class =~ s/::Set//g;
        my $obj = $class->get( id => params->{id} );
        unless ($obj) {
            die __PACKAGE__ . " No object found for id " . params->{id};
        }
        $msg = $value;
        $obj->$attr( $value );
        $obj->last_modified( time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
        UR::Context->commit();
    };
    if ($@) {
        warning "error: " . Data::Dumper::Dumper $@;
        return send_error();
    }
    return $msg;
};

post '/service/delete' => sub {
    my $self = shift;
    my $class = delete params->{class};
    $class =~ s/::Set//g;
    eval {
        my $obj = $class->get( params );
        $obj->delete;
        UR::Context->commit();
    };
    if ($@) {
        warning "error: " . Data::Dumper::Dumper $@;
        return send_error();
    }
    return;
};

# REST API to objects.
get qr{/view/(.*)/(.*)\.(.*)} => sub {
    warning "Using REST API route handler";
    my ( $class, $perspective, $toolkit ) = @{ delete params->{splat} };

    # This is in our XML/XSL UR stuff, should be made local to this package.
    $class = url_to_type($class);

    # Fix auto-camel-casing thing for SDM base class.
    $class =~ s/sdm/SDM/i;
    $perspective =~ s/\.$toolkit$//g;

    # flatten these where only one arg came in (don't want x=>['y'], just x=>'y')
    my $args = params;
    for my $key ( keys %$args ) {
        if ( index( $key, '_' ) == 0 ) {
            delete $args->{$key};
            next;
        }
        my $value = $args->{$key};
    }

    # Begin building args for UR query.
    my %view_special_args;
    for my $view_key (grep {$_=~ m/^-/} keys %$args) {
        $view_special_args{substr($view_key,1,length($view_key))} = delete $args->{$view_key}; 
    }

    my @matches;
    # An Object::Set view is different than an Object view.
    my $classname = $class->__meta__->class_name;
    if ($class->isa("UR::Object::Set")) {
        $class =~ s/::Set$//;
        eval { @matches = $class->define_set(%$args); };
    } else {
        eval { @matches = $class->get(%$args); };
        # More than one result is made into a set.
        if (@matches > 1) {
            eval { @matches = $class->define_set(%$args); };
        }
    }
    if ($@) {
        return send_error "Invalid arguments to define_set or get: " . Data::Dumper::Dumper $args;
    }

    unless (@matches) {
        return send_error "No object found";
    }

    # We get either 1 set or 1 object.
    return send_error "Matched too many, list not supported" unless ( @matches == 1 );

    my %view_args = (
        perspective => $perspective,
        toolkit     => $toolkit
    );

    # This is the default UR XML -> XSL translation layer.
    # Default object views are XML documents transformed to HTML via XSL.
    if ( $toolkit eq 'xsl' || $toolkit eq 'html' ) {
        $view_args{'xsl_root'} = SDM->base_dir . '/xsl';    ## maybe move this to $res_path?
        $view_args{'xsl_path'} = '/static/xsl';
        $view_args{'xsl_variables'} = {
            rest      => '/view',
            resources => '/view/sdm/resource.html'
        };
    }

    # All objects in UR have create_view
    # this probably ought to be revisited for performance reasons because it has to do a lot of hierarchy walking
    my $view;
    my $result = shift @matches;
    # Our first create_view attempt will find explicit Object View definitions.
    eval {
        $view = $result->create_view(%view_args, %view_special_args);
    };
    unless ($view) {
        # Try the default view
        $view_args{perspective} = 'default';
        eval {
            $view = $result->create_view(%view_args, %view_special_args);
        };
    }
    if ($@) {
        return send_error "No view found: $@";
    }
    return send_error "No view found" unless ($view);

    # I don't know why we have to set to 200 here, should be that by default.
    return $view->content();
};

1;
