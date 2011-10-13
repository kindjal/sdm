
package SDM::Zenoss::Process::Device;

class SDM::Zenoss::Process::Device {
    is => 'UR::Value::HASH',
    id_by => [
        id => { is => 'Number' }
    ],
    has => [
        uid => { is => 'Text' },
        name => { is => 'Text' },
        device => { is => 'Text' },
        status => { is => 'JSON::XS::Boolean' },
    ]
};


package SDM::Zenoss::Process;

use SDM;
use Zenoss;

class SDM::Zenoss::Process {
    id_by => {
        id => { is => 'Number' }
    },
    has => [
        uid => { is => 'Text' },
        processname => { is => 'Text' },
        status => { is => 'Text' },
        name => { is => 'Text' },
        monitored => { is => 'JSON::XS::Boolean' },
        device => { is => 'SDM::Zenoss::Process::Device' }
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
    my $response = $class->_api->connection->process_getInstances(
        {
            uid => '/',
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
    my $devid;
    foreach my $result ( @{ $response->decoded->{data} } ) {
        $result->{id} = $id++;
        # UR doesn't allow camel case attribute names
        my $lcresult;
        while (my ($key, $value) = each %$result) {
            if ($key eq 'device') {
                $value->{id} = $devid++;
                $lcresult->{lc($key)} = SDM::Zenoss::Process::Device->create( $value );
            } else {
                $lcresult->{lc($key)} = $value;
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
    my $response = $self->_api->connection->process_getInfo(
        {
            uid => $self->uid
        }
    );
    return $response->decoded;
}

sub getInstances {
    my $self = shift;
    my $info;
    my $response = $self->_api->connection->process_getInstances(
        {
            uid => $self->uid
        }
    );
    return $response->decoded;
}

1;
