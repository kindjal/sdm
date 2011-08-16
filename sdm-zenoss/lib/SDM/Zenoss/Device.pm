
package SDM::Zenoss::Device;

use SDM;
use Zenoss;

class SDM::Zenoss::Device {
    id_by => {
        uid => { is => 'Text' }
    },
    has => [
        events => {
            is => 'Hash'
        },
        name => { is => 'Text' },
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

    # Should only create() API the first time.
    my $response = $class->_api->connection->device_getDevices(
        {
            #params => { deviceClass => '/Server' },
            start => 0,
            limit => undef,
            sort => uid,
            dir => 'ASC',
        }
    );
    if ( $response->decoded->{message} =~ /error/i ) {
        warn $response->decoded->{message};
        return \@header, \@rows;
    }

    my $id;
    foreach my $result ( @{ $response->decoded->{devices} } ) {
        $result->{id} = $id++;
        # UR doesn't allow camel case attribute names
        my $lcresult;
        while (my ($key, $value) = each %$result) {
            $lcresult->{lc($key)} = $value;
        }
        # make IP a class
        while (my ($key, $value) = each %$lcresult) {
            if ($key eq 'ipaddress') {
                next unless ($value);
                $lcresult->{lc($key)} = SDM::Value::Ipaddress->get_or_create( id => $value );
            }
        }
        # Ensure values are in the same order as the header row.
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
    );
    return $response->decoded;
}

sub getComponents {
    my $self = shift;
    my $info;
    my $response = $self->_api->connection->device_getComponents(
        {
            uid => $self->uid
        }
    );
    return $response->decoded;
}

sub getBoundTemplates {
    my $self = shift;
    my $info;
    my $response = $self->_api->connection->device_getBoundTemplates(
        {
            uid => $self->uid
        }
    );
    return $response->decoded;
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

1;
