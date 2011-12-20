
package Sdm::Dancer::Handlers;

use strict;
use warnings;

use Sdm;
use JSON;
use Dancer ':syntax';
use Date::Format qw/time2str/;

get '/' => sub {
    return default_route();
};

get qr{/((?!view).*)} => sub {
    return static_content();
};

get qr{/view/(.*)/(.*)\.(.*)} => sub {
    return rest_handler();
};

post '/service/add' => sub {
    return add_handler();
};

post '/service/update' => sub {
    return update_handler();
};

post '/service/delete' => sub {
    delete_handler();
};

post '/service/lsof' => sub {
    return lsof_handler( params->{data} );
};

sub url_to_type {
    join(
        '::',
        map {
            $_ = ucfirst;
            s/-(\w{1})/\u$1/g;
            $_;
          } split( '/', $_[0] )
    );
}

sub default_route {
    return send_error("Default search page not yet implemented");
}

sub static_content {
    warn "Using static content route handler: " . Data::Dumper::Dumper splat;
    my ($file) = splat;
    my $path = Sdm->base_dir . '/public';
    return send_file("$path/$file", system_path => 1);
}

sub add_handler {
    # What kind of object are we adding?
    my $class = delete params->{class};
    # Don't confuse UR, let it come up with the id.
    delete params->{id};
    # Everything's a Set, no need to say it.
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
        return "Error: $@";
    }
    warn "returning: " . $obj->id;
    # Send back the ID, which should be used by
    # datatables editable as a new row id.  This fails to be used in the added row
    # because "jquery-editable" looks for a class="id" which we use elsewhere.  This
    # name conflict of "id" prevents the proper auto-adding of the id attribute to the new row.
    return $obj->id;
}

sub update_handler {
    # Load the requested namespace
    my $class = delete params->{class};
    my ($namespace,$toss) = split(/\:\:/,$class,2);
    $namespace = ucfirst(lc($namespace));

    my $attr = params->{columnName};
    my $value = params->{value};
    $class =~ s/::Set//g;

    my $msg;
    eval {
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
        return "Error: $@";
    }
    return $msg;
}

sub delete_handler {
    my $class = delete params->{class};
    $class =~ s/::Set//g;
    unless (params->{id}) {
        # This usually happens when someone tries to delete a row they
        # just added.  jQuery has added the row to the DB but doesn't
        # have it in the page yet.  Refresh and try again.
        return "This row has no 'id'.  Refresh the page and try again.";
    }

    # Load the requested namespace
    my ($namespace,$toss) = split(/\:\:/,$class,2);
    $namespace = ucfirst(lc($namespace));

    eval {
        my $obj = $class->get( params );
        unless ($obj) {
            return "no object found matching the query: " . Data::Dumper::Dumper params;
        }
        $obj->delete;
        UR::Context->commit();
    };
    if ($@) {
        return "Error: $@";
    }
}

sub rest_handler {
    warn "Using REST API route handler";
    warning "Using REST API route handler";
    my ( $class, $perspective, $toolkit ) = @{ delete params->{splat} };

    # This is in our XML/XSL UR stuff, should be made local to this package.
    $class = url_to_type($class);

    # Load the requested namespace
    my ($namespace,$toss) = split(/\:\:/,$class,2);
    $namespace = ucfirst(lc($namespace));

    # Support our old REST scheme of view/namespace/object/set/perspective.toolkit
    # by removing ::Set, we assume everything is a Set now.
    $class =~ s/::Set//;

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

    my $set;
    eval { $set = $class->define_set(%$args); };
    if ($@) {
        return "Error: $@";
    }
    unless ($set) {
        return send_error("No object set found",500);
    }

    unless ($set->count) {
        warn "no objects found";
        my $path = Sdm->base_dir . '/Service/WebApp/public/empty.html';
        return send_file($path, system_path => 1);
    }

    my %view_args = (
        perspective => $perspective,
        toolkit     => $toolkit
    );

    # FIXME:
    # Can we replace this with Dancer's XML plugins?
    # This is the default UR XML -> XSL translation layer.
    # Default object views are XML documents transformed to HTML via XSL.
    if ( $toolkit eq 'xsl' || $toolkit eq 'html' ) {
        $view_args{'xsl_root'} = $namespace->base_dir . '/xsl';    ## maybe move this to $res_path?
        $view_args{'xsl_path'} = '/static/xsl';
        $view_args{'html_root'} = $namespace->base_dir . '/View/Resource/Html/html';
        $view_args{'xsl_variables'} = {
            rest      => '/view',
            # Is this actually used?  I think this builds a URL in an old-fashioned
            # /view/$namespace/resource.html/foo.bar scheme that I'm not sure we do.
            resources => "/view/$namespace/resource.html"
        };
    }

    # All objects in UR have create_view
    # this probably ought to be revisited for performance reasons because it has to do a lot of hierarchy walking
    my $view;

    # Our first create_view attempt will find explicit Object View definitions.
    eval {
        $view = $set->create_view(%view_args, %view_special_args);
    };
    if ($@ or ! defined $view) {
        # Try again with Sdm default object set.
        warn "No view found: " . $@;
        $view_args{subject_class_name} = "Sdm::Object::Set";
        eval {
            $view = $set->create_view(%view_args, %view_special_args);
        };
    }
    if ($@ or ! defined $view) {
        # Try again with UR Object Set.
        warn "No view found: " . $@;
        $view_args{subject_class_name} = "UR::Object::Set";
        eval {
            $view = $set->create_view(%view_args, %view_special_args);
        };
    }
    if ($@ or ! defined $view) {
        # Try the default view
        warn "No view found: " . $@;
        warn "looking for default view";
        $view_args{perspective} = 'default';
        eval {
            $view = $set->create_view(%view_args, %view_special_args);
        };
    }
    if ($@) {
        return send_error("Error in create_view(): $@");
    }
    return send_error("No view found",404) unless ($view);

    return $view->content();
}

sub lsof_handler {
    my $content = shift;
    my $json = JSON->new;
    my $data = $json->decode($content);

    # Get the hostname from the first key of first record
    my $hostname = shift @{ [ keys %$data ] };
    my $records = $data->{$hostname};

    unless (ref($records) =~ /^HASH/) {
        print STDERR __PACKAGE__ . " agent at $hostname reports problem: $records\n";
        return 0;
    }

    # Remove existing records not just returned in JSON.
    # FIXME: Only delete objects from the same hostname, so that
    #   worker1 does not delete objects for host A while worker2 processes a new POST.
    #foreach my $existing (Sdm::Service::Lsof::Process->get( hostname => $hostname )) {
    #    my $key = $existing->hostname . "\t" . $existing->pid;
    #    $existing->delete unless (exists $records->{$key});
    #}
    foreach my $existing (Sdm::Service::Lsof::Process->get()) {
        if ($hostname and $existing->hostname eq $hostname) {
            # Clean expired processes from live hosts reporting in 
            my $key = $existing->hostname . "\t" . $existing->pid;
            $existing->delete unless (exists $records->{$key});
        } else {
            # Clean processes whose hosts have not reported in in 1/2 day
            my $err;
            my $age = $existing->age;
            $existing->delete if ($age > 16200);
        }
    }

    # Enter fresh JSON records.
    foreach my $key (keys %$records) {
        my $record = delete $records->{$key};
        my $pid;
        # Skip /proc files and kernel threads
        next if ( grep { /^(\/proc|\[.*\])/ } @{ $record->{name} } );

        ($hostname,$pid) = split("\t",$key);
        $record->{hostname} = $hostname;
        $record->{pid} = int($pid);

        my $process = Sdm::Service::Lsof::Process->get( hostname => $hostname, pid => $pid );
        if ($process) {
            $process->update($record);
        } else {
            $process = Sdm::Service::Lsof::Process->create( $record );
            unless ($process) {
                die "failed to create new process record: $!";
            }
        }
    }

    # Determine list of changes
    my @added = grep { $_->__changes__ } $UR::Context::current->all_objects_loaded('Sdm::Service::Lsof::Process');
    my @removed = $UR::Context::current->all_objects_loaded('UR::Object::Ghost');
    my @changes = (@added,@removed);

    # We're about to commit().  UR catches RDBMS errors and pushes them into a stack which
    # we copy here.  Then if commit returns undef, we examine the stack for known error conditions.
    my @errors;
    UR::Context->message_callback('error', sub { push @errors, $_[0]->text });
    my $rc = UR::Context->commit();
    unless ($rc) {
        if ( grep { /are not unique/ } @errors ) {
            push @errors, "Two agents running on the same host!";
        }
        my $msg = join(", ",@errors);
        # Die so our dispatcher can return 500 to client.
        die "commit failed, rolled back: $msg";
    }
    # Unload new objects so we don't get UR errors like:
    # Process ID 'blade11-2-15.gsc.wustl.edu     21426' has just been loaded, but it exists in the application as a new unsaved object!
    foreach my $obj (@added) {
        $obj->unload;
    }

    return scalar @changes;
}

1;
