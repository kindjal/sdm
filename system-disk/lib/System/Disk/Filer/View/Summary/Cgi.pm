
package System::Disk::Filer::View::Summary::Cgi;

use strict;
use warnings;

use System;
use JSON;
use URI;
use URI::QueryParam;

class System::Disk::Filer::View::Summary::Cgi {
    is => 'System::Disk::View::Cgi'
};

=head2 run
Receive a URI string as an argument, fetch data, turn it into JSON and return it.
=cut
sub run {

    my ($self,$uri) = @_;
    $self->{logger}->debug(__PACKAGE__ . " run");
    my $query = URI->new( $uri );

    my $result = { total_kb => 0, used_kb => 0, last_modified => '0000:00:00:00:00:00' };

    my $set = System::Disk::Volume->define_set();
    $result->{total_kb} = $set->sum('total_kb');
    $result->{used_kb} = $set->sum('used_kb');

    $set = System::Disk::Volume->define_set( -group_by => [ 'last_modified' ], -order_by => [ 'last_modified' ] );
    my $r = pop @{ [ $set->members ] };
    $result->{last_modified} = $r->{last_modified} ? $r->{last_modified} : $result->{last_modified};

    $result->{capacity} = 0;
    if ($result->{total_kb}) {
        $result->{capacity} = $result->{used_kb} / $result->{total_kb} * 100;
    }

    # Prettify if desired by server side processing query
    unless ($query->query_form_hash->{_}) {
        $result->{total_kb} = $self->_commify($result->{total_kb}) . " (" . $self->_short($result->{total_kb}) . ")";
        $result->{used_kb}  = $self->_commify($result->{used_kb}) . " ("  . $self->_short($result->{used_kb}) . ")";
        $result->{capacity} = sprintf "%d %%", $result->{capacity};
    }

    my $json = new JSON;
    return $json->encode($result);
}

1;
