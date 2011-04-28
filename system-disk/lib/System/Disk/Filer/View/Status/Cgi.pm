
package System::Disk::Filer::View::Status::Cgi;

use strict;
use warnings;

use System;

class System::Disk::Filer::View::Status::Cgi {
    is => 'System::Disk::View::Cgi'
};

=head2 _fnColumnToField
This maps a column in DataTables to a UR::Object attribute.
=cut
sub _fnColumnToField {
    my $self = shift;
    $self->{logger}->debug("_fnColumnToField: map DataTable column to UR::Object attribute");
    my $i = shift;

    # Note: we could have used an array, but for dispatching purposes, this is
    # more readable. These are the column names on the disk summary datatable.
    my %dispatcher = (
            # column => 'rowname',
            0 => 'name',
            1 => 'status',
            2 => 'hostname',
            3 => 'arrayname',
            4 => 'created',
            5 => 'last_modified',
            );

    die("No such row index defined: $i") unless exists $dispatcher{$i};

    return $dispatcher{$i};
}

=head2 _build_result_set
Get the set of Filers represented by a DataTables query.
=cut
sub _build_result_set {
    my ($self,$q) = @_;
    $self->{logger}->debug("_build_result_set: fetch UR::Objects and return a UR::Object::Set");

    my $param = {};
    my @where = $self->_build_where_param($q);
    if (scalar @where) {
        $param->{ -or } = \@where;
    }

    my @result = System::Disk::Filer->get( $param );
    return @result;
}

=head2 _build_aadata
Order and sort our UR::Object::Set as well as applying some modifiers and transformations.
=cut
sub _build_aadata {
    my $self = shift;
    $self->{logger}->debug("_build_aadata: convert a UR::Object::Set");
    my $query = shift;
    my @results = @_;
    return unless (@results and $results[0]->isa( 'System::Disk::Filer' ) );
    my @data;
    foreach my $item ( @results ) {
        my $hostname = 'unknown';
        my @hosts = $item->hostname;
        if (@hosts) {
            $hostname = join(",",@hosts);
        }
        my $arrayname = 'unknown';
        my @arrays = $item->arrayname;
        if (@arrays) {
            $arrayname = join(",",@arrays);
        }

        push @data, [
            $item->{name},
            $item->{status},
            $hostname,
            $arrayname,
            $item->{created} ? $item->{created} : "0000-00-00 00:00:00",
            $item->{last_modified} ? $item->{last_modified} : "0000-00-00 00:00:00",
        ];
    }

    my @sorted_data = $self->_sorter($query,@data);

    # Now that we have the data, unload it from memory so that we are
    # forced to fetch a fresh copy the next time a request is made.
    System::Disk::Filer->unload();

    return @sorted_data;
}

1;
