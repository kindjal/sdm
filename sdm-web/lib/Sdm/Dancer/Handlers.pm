
package Sdm::Dancer::Handlers;

use strict;
use warnings;

use Sdm;
use JSON qw//; # Don't load what JSON exports so we don't fight with Dancer.
use Dancer ':syntax';
use Date::Format qw/time2str/;
use Data::Dumper;
use HTML::Entities;

set appdir => Sdm->base_dir;
set public => Sdm->base_dir . "/public";
set views => Sdm->base_dir . "/views";
warn "reset dancer appdir to " . Sdm->base_dir;

get '/' => sub {
    return _error_template("SDM is ready to serve!  Ask me for a URL that I know about.","success");
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

# The default route handler should be last
any qr{.*} => sub {
    my $path = request->uri();
    warn "default route handler: $path";
    return _error_template("You tried to reach '$path' which has no handler.  Contact the developer to report this if you think it should be present.");
};

sub _serialize {
    my $obj = shift;
    my $d = Data::Dumper->new([$obj]);
    $d->Indent(0)->Terse(1);
    return $d->Dump();
}

sub _error_template {
    my $msg = shift;
    my $class = shift;
    $class = 'error' unless ($class);
    my $heading = ucfirst(lc($class));
    $msg = encode_entities($msg);
    return template 'error.tt', { heading => $heading, class => $class, message => '<pre>' . $msg . '</pre>' };
}

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

sub static_content {
    warn "static content route handler: " . _serialize(splat);
    my ($file) = splat;
    my $path = Sdm->base_dir . '/public/' . $file;
    if (-e $file) {
        return send_file("$path/$file", system_path => 1);
    } else {
        return _error_template("This file or view does not exist: $path/$file");
    }
}

sub add_handler {
    warn "add route handler";
    # What kind of object are we adding?
    my $class = delete params->{class};

    # Don't confuse UR, let it come up with the id.
    delete params->{id};
    # Everything's a Set, no need to say it.
    $class =~ s/::Set$//;

    # Remove non-editable params
    my $params = params;
    my %newparams = %$params;
    my @editable;
    if ( $class->default_aspects and exists $class->default_aspects->{editable} ) {
        @editable = @{ $class->default_aspects->{editable} };
    }
    if (@editable) {
        @newparams{@editable} = @$params{@editable};
        # Remove empty params to allow creation to use the target object's default value
        foreach my $key (keys %newparams) {
            delete $newparams{$key} unless ( $newparams{$key} );
        }
    }

    my $obj;
    my $rc;
    eval {
        $obj = $class->create( \%newparams );
        unless ($obj) {
            die "Failed to create object";
        }
        $rc = UR::Context->commit();
        unless ($rc) {
            die "Failed to commit new object";
        }
    };
    if ($@) {
        return _error_template("Failed to save new object: $@");
    }
    # Send back the ID, which should be used by
    # datatables editable as a new row id.  This fails to be used in the added row
    # because "jquery-editable" looks for a class="id" which we use elsewhere.  This
    # name conflict of "id" prevents the proper auto-adding of the id attribute to the new row.
    return $obj->id;
}

sub update_handler {
    warn "update route handler";
    my $class = delete params->{class};
    # Column name comes from aoColumns sTitle in datatable
    my $attr = params->{columnName};
    my $value = params->{value};
    $class =~ s/::Set//g;

    my $msg;
    eval {
        my $obj = $class->get( id => params->{id} );
        unless ($obj) {
            die "No object found for id " . params->{id};
        }
        $msg = $value;
        $obj->$attr( $value );
        $obj->last_modified( time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
        my $rc = UR::Context->commit();
        unless ($rc) {
            die "Failed to commit update";
        }
    };
    if ($@) {
        if ($@ =~ /No object found for id/) {
            return "No object found for id. Try refreshing the page then editing the row.";
        } else {
            return "Error: $@";
        }
    }
    return $msg;
}

sub delete_handler {
    warn "delete route handler";
    my $class = delete params->{class};
    $class =~ s/::Set//g;
    unless (params->{id}) {
        # This usually happens when someone tries to delete a row they
        # just added.  jQuery has added the row to the DB but doesn't
        # have it in the page yet.  Refresh and try again.
        return _error_template("This row has no 'id'.  Refresh the page and try again.");
    }

    eval {
        my $obj = $class->get( params );
        unless ($obj) {
            return _error_template("no object found matching the query: " . _serialize(params));
        }
        $obj->delete;
        UR::Context->commit();
    };
    if ($@) {
        # This is going to a browser dialog box, not a web page.
        return "Error: $@";
    }
}

sub rest_handler {
    warn "REST route handler";
    my ( $class, $perspective, $toolkit ) = @{ delete params->{splat} };


    # This is in our XML/XSL UR stuff, should be made local to this package.
    $class = url_to_type($class);

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

    my $subject;
    eval { $subject = $class->define_set($args); };
    if ($@) {
        my $msg = "Error in REST handler: $class: " . _serialize($args) . ": $@";
        return _error_template($msg);
    }
    unless ($subject) {
        return send_error("No object set found",500);
    }

    if ($class eq 'Sdm') {
        my $msg = sprintf "You aren't asking for a known object.  Please inspect the URL and try again.";
        return _error_template($msg,'notice');
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
        $view_args{'xsl_root'} = Sdm->base_dir . '/xsl';    ## maybe move this to $res_path?
        $view_args{'xsl_path'} = '/static/xsl';
        $view_args{'html_root'} = Sdm->base_dir . '/View/Resource/Html/html';
        $view_args{'xsl_variables'} = {
            rest      => '/view',
            # Is this actually used?  I think this builds a URL in an old-fashioned
            # /view/$namespace/resource.html/foo.bar scheme that I'm not sure we do.
            resources => "/view/sdm/resource.html"
        };
    }

    # All objects in UR have create_view
    # this probably ought to be revisited for performance reasons because it has to do a lot of hierarchy walking
    my $view;

    # Our first create_view attempt will find explicit Object View definitions.
    eval {
        $view = $subject->create_view(%view_args, %view_special_args);
    };
    if ($@ or ! defined $view) {
        # Try again with Sdm default object set.
        warn "No view found: " . $@;
        $view_args{subject_class_name} = "Sdm::Object::Set";
        warn "Trying " .  $view_args{subject_class_name};
        eval {
            $view = $subject->create_view(%view_args, %view_special_args);
        };
    }
    if ($@ or ! defined $view) {
        # Try again with UR Object Set.
        warn "No view found: " . $@;
        $view_args{subject_class_name} = "UR::Object::Set";
        warn "Trying " .  $view_args{subject_class_name};
        eval {
            $view = $subject->create_view(%view_args, %view_special_args);
        };
    }
    if ($@ or ! defined $view) {
        # Try the default view
        warn "No view found: " . $@;
        $view_args{perspective} = 'default';
        warn "Trying " .  $view_args{subject_class_name};
        eval {
            $view = $subject->create_view(%view_args, %view_special_args);
        };
    }
    if ($@) {
        return send_error("Error in create_view(): $@");
    }
    return send_error("No view found",404) unless ($view);

    return $view->content();
}

sub lsof_handler {
    warn "lsof route handler";
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
