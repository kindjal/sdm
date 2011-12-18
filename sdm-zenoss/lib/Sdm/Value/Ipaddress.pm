
package Sdm::Value::Ipaddress;

class Sdm::Value::Ipaddress {
    is => 'UR::Value::Number',
};

sub __display_name__ {
    my $self = shift;
    return join '.', unpack 'C4', pack 'N', $self->id;
}

1;
