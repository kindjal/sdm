#!/usr/bin/perl

package SDM::Service::WebApp::Asset;

use strict;
use warnings;

#use Web::Simple 'SDM::Service::WebApp::Asset';
use Dancer;

use Data::Dumper;
$Data::Dumper::Indent = 1;

our $loaded = 0;
sub load_modules {
    return if $loaded;
    eval "
        use SDM;
        use JSON;
        use Date::Manip;
    ";
    if ($@) {
        die "failed to load required modules: $@";
    }
    my $dbh = SDM::DataSource::Service->_singleton_object->_default_dbh;
    SDM::DataSource::Service->_singleton_object->disconnect_default_handle if ($dbh);

    # search's callbacks are expensive, web server can't change anything anyway so don't waste the time
    SDM::Search->unregister_callbacks('UR::Object');

    $loaded = 1;
}

=head2 process
=cut
sub process {
    my $self = shift;

    #my $content = shift;
    #my $json = JSON->new;
    #my $data = $json->decode($content);

    # Enter fresh JSON records.
    #warn "post data: " . Data::Dumper::Dumper $data;

    # We're about to commit().  UR catches RDBMS errors and pushes them into a stack which
    # we copy here.  Then if commit returns undef, we examine the stack for known error conditions.
    #UR::Context->message_callback('error', sub { push @errors, $_[0]->text });
    #UR::Context->commit();
}

post '/service/asset' => sub {

    my $self = shift;
    my ($params) = @_;
    my $msg = "OK";

    warn "args " . Data::Dumper::Dumper @_;
    warn "params " . Data::Dumper::Dumper params;

    eval {
        #$self->process();
        my $attr = params->{columnName};
        my $value = params->{value};
        my $obj = SDM::Asset::Hardware->get( manufacturer => params->{id} );
        $obj->$attr( $value );
        UR::Context->commit();
    };
    if ($@) {
        $msg = __PACKAGE__ . " Error in process: $@";
        # Print to local error log
        send_error($msg, 500);
    }

    warn "return $msg";
    return $msg;
};

dance;
