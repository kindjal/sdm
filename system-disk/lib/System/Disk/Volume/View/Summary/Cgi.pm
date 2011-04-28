
package System::Disk::Volume::View::Summary::Cgi;

use strict;
use warnings;

use System;

class System::Disk::Volume::View::Summary::Cgi {
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
            0 => 'disk_group',
            1 => 'total_kb',
            2 => 'used_kb',
            3 => 'capacity',
            );

    die("No such row index defined: $i") unless exists $dispatcher{$i};

    return $dispatcher{$i};
}

=head2 _build_query_param
Convert URI query object to UR::Object parameter hash.
=cut
sub _build_query_param {
    my ($self,$q) = @_;
    $self->{logger}->debug("_build_query_param");
    my $param = {};

    my @where = $self->_build_where_param($q);
    if (scalar @where) {
        $param->{ -or } = \@where;
    }

    my @group = ['disk_group'];
    if (scalar @group) {
        $param->{ -group_by } = ['disk_group'],
    }

    return $param;
}

=head2 _build_result_set
Get the set of Volumes represented by a DataTables query.
=cut
sub _build_result_set {
    my ($self,$q) = @_;
    $self->{logger}->debug("_build_result_set: fetch UR::Objects and return a UR::Object::Set");
    my $param = $self->_build_query_param($q);
    my @results = System::Disk::Volume->get( $param );
    return @results;
}

=head2 _build_aadata
Order and sort our UR::Object::Set as well as applying some modifiers and transformations.
=cut
sub _build_aadata {
    my $self = shift;
    $self->{logger}->debug("_build_aadata: convert a UR::Object::Set");
    my $query = shift;
    my @results = @_;
    # @results must be a non-empty array of arrays of volumes
    return unless (@results and $results[0]->isa( 'System::Disk::Volume::Set' ));
    my @data;
    foreach my $item ( @results ) {
        my $capacity = 0;
        if ($item->sum('total_kb')) {
            $capacity = $item->sum('used_kb') / $item->sum('total_kb') * 100;
        }
        push @data, [
            $item->disk_group ? $item->disk_group : 'unknown',
            $item->sum('total_kb'),
            $item->sum('used_kb'),
            $capacity,
        ];
    }
    my @sorted_data = $self->_sorter($query,@data);
    # Unload so we are sure to fetch fresh data at next run.
    System::Disk::Volume->unload();
    return @sorted_data;
}

=head2 _prettify_aadata
Adds commas and readability stuff to our aaData.
=cut
sub _prettify_aadata {
    my $self = shift;
    $self->{logger}->debug("_prettify_aadata");
    my @data = @_;
    # @data must be a non-empty array of arrays of size 4
    return unless (@data and scalar @{ $data[0] } );
    @data = map { [
         $_->[0],
         $self->_commify($_->[1]) . " (" . $self->_short($_->[1]) . ")",
         $self->_commify($_->[2]) . " (" . $self->_short($_->[2]) . ")",
         sprintf("%d %%", $_->[3]),
       ] } @data;
    return @data;
}

1;
