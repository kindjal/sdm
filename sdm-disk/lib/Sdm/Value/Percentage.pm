
package Sdm::Value::Percentage;

class Sdm::Value::Percentage {
    is => 'UR::Value::Number',
};

sub __display_name__ {
    my $self = shift;
    return sprintf "%02d %%", $self->id;
}

1;
