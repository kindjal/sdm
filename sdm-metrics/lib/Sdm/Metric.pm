
package Sdm::Metric;

use strict;
use warnings;

use Sdm;
use AnyEvent::Graphite;

sub new {
    my $class = shift;
    my $self = {
        name => undef,
        collector => '127.0.0.1'
    };
    bless $self,$class;
    return $self;
};

sub name {
    my $self = shift;
    $self->{name} = shift unless ($self->{name});
    return $self->{name};
}

sub report {
    my $self = shift;
    unless ( $self->{name} ) {
        warn __PACKAGE__ . " unnamed metric trying to report, aborting";
        return;
    }
    unless ( $self->value ) {
        warn __PACKAGE__ . " metric without value trying to report, aborting";
        return;
    }

    my $graphite = AnyEvent::Graphite->new(
        host => $self->{collector},
        port => '2003',
    );

    $graphite->send($self->name,$self->value,time);
    $graphite->finish();
    return 1;
}

1;
