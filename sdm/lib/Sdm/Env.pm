
package Sdm::Env;

class Sdm::Env {
    is => "UR::Value"
};

sub value {
    my $self = shift;
    my $name = pop @{ [ split('::', $self->__meta__->class_name ) ] };
    return $ENV{ $name };
}
