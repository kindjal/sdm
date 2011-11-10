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

post '/service/asset' => sub {

    my $self = shift;
    my $msg;
    eval {
        my $attr = params->{columnName};
        my $value = params->{value};
        my $obj = SDM::Asset::Hardware->get( id => params->{id} );
        unless ($obj) {
            return send_error(__PACKAGE__ . " No object found for id " . params->{id});
        }
        $msg = $value;
        $obj->$attr( $value );
        UR::Context->commit();
    };
    if ($@) {
        return send_error(__PACKAGE__ . " Error in process: $@",500);
    }

    return $msg;
};

dance;
