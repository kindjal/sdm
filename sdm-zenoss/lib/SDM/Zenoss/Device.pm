
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
    ]
};

sub __load__ {
    my ($class, $bx, $headers) = @_;

    # Make a header row from class properties.
    my @header = $class->__meta__->property_names;

    # Return an empty list if error.
    my @rows = [];

    my $API = SDM::Zenoss::API->create();
    my $response = $API->connection->device_getDevices(
        {
            #params => { deviceClass => '/Server' },
        }
    );

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
                my $ip = SDM::Value::Ipaddress->create($value);
                $lcresult->{lc($key)} = $ip;
            }
        }
        # Ensure values are in the same order as the header row.
        my @row = map { $lcresult->{$_} } @header;
        push @rows, [@row];
    }

    return \@header, \@rows;
}

1;
