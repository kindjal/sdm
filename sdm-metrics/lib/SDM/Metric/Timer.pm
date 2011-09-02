
package SDM::Metric::Timer;

use strict;
use warnings;

use SDM::Metric;
use base "SDM::Metric";

sub new {
    my $class = shift;
    my $self = {
        name => shift,
        collector => '127.0.0.1',
        port => '2003',
        starttime => undef,
        stoptime => undef,
        value => undef,
    };
    bless $self,$class;
    return $self;
};

sub value {
    my $self = shift;
    return undef unless (defined $self->{starttime} and defined $self->{stoptime});
    return $self->{stoptime} - $self->{starttime};
}

sub start {
    my $self = shift;
    $self->{starttime} = time unless ($self->{starttime});
    return $self->{starttime};
}

sub stop {
    my $self = shift;
    $self->{stoptime} = time unless ($self->{stoptime});
    return $self->{stoptime};
}

1;
