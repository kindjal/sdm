
package System::Disk::Volume::View::Summary::Cgi;

use strict;
use warnings;

use System;
use JSON;
use URI;
use URI::QueryParam;

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
    return @data unless @data;

    # Implement Set ordering here, note that the Web UI (DataTables) supports
    # multi column sort, which is nice with direct DB call, but here we must
    # sort UR::Object::Sets which are by definition unordered.  Just do one column sort.
    my @order = $self->_build_order_param($query);
    my $order_col = $order[0][0];
    my $order_dir = $order[0][1];

    if ($order_dir and $order_col and $order_dir eq 'asc') {
        if ( $data[0][ $order_col ] =~ /\d+/ ) {
            @data = sort { $a->[ $order_col ] <=> $b->[ $order_col ] } @data;
        } else {
            @data = sort { $a->[ $order_col ] cmp $b->[ $order_col ] } @data;
        }
    } elsif ($order_col) {
        if ( $data[0][ $order_col ] =~ /\d+/ ) {
            @data = sort { $b->[ $order_col ] <=> $a->[ $order_col ] } @data;
        } else {
            @data = sort { $b->[ $order_col ] cmp $a->[ $order_col ] } @data;
        }
    }

    # Implement limit and offset here to make up for lack of feature in get();
    sub max ($$) { int($_[ $_[0] < $_[1] ]) };
    sub min ($$) { int($_[ $_[0] > $_[1] ]) };
    my $limit  = $query->query_param('iDisplayLength') || 10;
    my $offset = $query->query_param('iDisplayStart') || 0;
    my $ceiling = min($limit-1,$#data);
    my @aaData = @data[$offset..$ceiling];

    return @data;
}

=head2 _prettify_aadata
Adds commas and readability stuff to our aaData.
=cut
sub _prettify_aadata {
    my $self = shift;
    $self->{logger}->debug("_prettify_aadata");
    my @data = @_;
    return [] unless @data;
    @data = map { [
         $_->[0],
         $self->_commify($_->[1]) . " (" . $self->_short($_->[1]) . ")",
         $self->_commify($_->[2]) . " (" . $self->_short($_->[2]) . ")",
         sprintf("%d %%", $_->[3]),
       ] } @data;
    return @data;
}

=head2 run
Receive a URI string as an argument, fetch data, turn it into JSON and return it.
=cut
sub run {
    my ($self,$uri) = @_;
    $self->{logger}->debug(__PACKAGE__ . " run");
    my $query = URI->new( $uri );

    my @results = $self->_build_result_set( $query );
    my @aaData = $self->_build_aadata( $query, @results );
    @aaData = $self->_prettify_aadata( @aaData );

    my $sEcho = defined $query->query_param('sEcho') ? $query->query_param('sEcho') : 1;
    my $iTotal = scalar @results;
    my $iFilteredTotal = scalar @aaData;
    my $sOutput = {
        sEcho => $sEcho,
        iTotalRecords => int($iTotal),
        iTotalDisplayRecords => int($iFilteredTotal),
        aaData => \@aaData,
    };

    my $json = new JSON;
    my $result = $json->encode($sOutput);
    return $result
}

1;
