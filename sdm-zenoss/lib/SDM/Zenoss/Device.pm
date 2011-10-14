
package SDM::Zenoss::Device;

use SDM;
use Zenoss;

class SDM::Zenoss::Device {
    id_by => {
        id => { is => 'Text' }
    },
    has => [
        uid => { is => 'Text' },
        duid => { is => 'Text' },
        events => {
            is => 'Hash'
        },
        name => { is => 'Text' },
        deviceclass => { is => 'Text' },
        ipaddress => { is => 'SDM::Value::Ipaddress' },
        productionatate => { is => 'Text' },
    ],
};

sub _api {
    my $class = shift;
    our $API;
    $API ||= SDM::Zenoss::API->create();
    return $API;
}

sub __load__ {
    my ($class, $bx, $headers) = @_;
    # Make a header row from class properties.
    my @header = $class->__meta__->property_names;
    # Return an empty list if error.
    my @rows = [];
    foreach my $item ('name','ipAddress','deviceClass','productionState') {
        my $value = $bx->value_for(lc($item));
        $params->{$item} = $value if (defined $value);
    }
    my $uid = $bx->value_for('uid');
    my $response = $class->_api->connection->device_getDevices(
        {
            uid => $uid,
            params => $params,
            start => 0,
            limit => undef,
            sort => uid,
            dir => 'ASC',
        }
    )->decoded;
    if ( $response->{message} =~ /error/i ) {
        warn $response->{message};
        return \@header, \@rows;
    }
    my $id;
    foreach my $result ( @{ $response->{devices} } ) {
        $result->{id} = $id++;
        $result->{deviceclass} = $params->{deviceClass};
        # UR doesn't allow camel case attribute names
        my $lcresult;
        while (my ($key, $value) = each %$result) {
            $lcresult->{lc($key)} = $value;
        }
        $lcresult->{duid} = $lcresult->{uid};
        $lcresult->{uid} = $uid;
        # make IP address object
        while (my ($key, $value) = each %$lcresult) {
            if ($key eq 'ipaddress') {
                next unless ($value);
                $lcresult->{lc($key)} = SDM::Value::Ipaddress->get_or_create( id => $value );
            }
        }
        my @row = map { $lcresult->{$_} } @header;
        push @rows, [@row];
    }
    return \@header, \@rows;
}

sub getInfo {
    my $self = shift;
    my $info;
    my $response = $self->_api->connection->device_getInfo(
        {
            uid => $self->uid
        }
    )->decoded;
    return $response;
}

sub getComponents {
    my $self = shift;
    my $info;
    my $response = $self->_api->connection->device_getComponents(
        {
            uid => $self->uid
        }
    )->decoded;
    return $response;
}

sub getBoundTemplates {
    my $self = shift;
    my $info;
    my $response = $self->_api->connection->device_getBoundTemplates(
        {
            uid => $self->uid
        }
    )->decoded;
    return $response;
}

sub getDeviceClasses {
    my $self = shift;
    my $info;
    my $response = $self->_api->connection->device_getDeviceClasses(
        {
            uid => $self->uid
        }
    )->decoded;
    return $response;
}

sub getRRDValue {
    my $self = shift;
    my $dsname = shift;
    my $info;
    my $url = $self->_api->connection->connector->endpoint . $self->uid . "/getRRDValue?dsname=$dsname";
    my $query = HTTP::Request->new(GET => "$url");
    $query->content_type('application/json; charset=utf-8');

    my $response = $self->_api->connection->_agent->request($query);
    unless ($response->is_success && $response->code == 200) {
        return undef;
    }
    return $response->{_content};
}

#sub create {
#    my $self = shift;
#    my $bx = $self->define_boolexpr(@_);
#    no strict 'refs';
#    *{SDM::Zenoss::Device::foo} = sub { return 'foo'; };
#    return $self::SUPER->create($bx);
#}

1;
