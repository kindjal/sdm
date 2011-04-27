
package System::Disk::View::Cgi;

use strict;
use warnings;

class System::Disk::View::Cgi {
    # Because we're a System::Command::Base we get logger for free
    is => 'System::Command::Base'
};

=head2 _short
Convert a number of bytes to an abbreviated form: 1000 => 1 KB
=cut
sub _short {
    my $self = shift;
    $self->{logger}->debug("_short: convert number to abbreviated form");
    my $number = shift;
    return '' unless (defined $number);
    return $number unless ($number =~ /^\d+$/);

    my $cn = $self->_commify($number);
    my $size = 0;
    $size++ while $cn =~ /,/g;

    my $units = {
        0 => 'KB',
        1 => 'MB',
        2 => 'GB',
        3 => 'TB',
        4 => 'PB',
    };
    my $round = {
        0 => 1,
        1 => 1000,
        2 => 1000000,
        3 => 1000000000,
        4 => 1000000000000,
    };
    my $n = int($number / $round->{$size} + 0.5);
    return "$n " . $units->{$size};
}

=head2 _commify
Add commas to a long number: 1000 => 1,000
=cut
sub _commify {
    my $self = shift;
    $self->{logger}->debug("_commify: add commas to long number");
    my $number = shift;
    return '' unless (defined $number);
    return $number unless ($number =~ /^\d+$/);
    # commify a number. Perl Cookbook, 2.17, p. 64
    my $text = reverse $number;
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

=head2 _build_order_param
Convert a DataTables URI to an 'order' clause
=cut
sub _build_order_param {
    my ($self,$q) = @_;
    $self->{logger}->debug("_build_order_param: convert DataTables URI to an 'order' clause");
    my @order;
    if( defined $q->query_param('iSortCol_0') ){
        for( my $i = 0; $i < $q->query_param('iSortingCols'); $i++ ) {
            # We only get the column index (starting from 0), so we have to
            # translate the index into a column name.
            my $col = $q->query_param('iSortCol_'.$i);
            my $dir = $q->query_param('sSortDir_'.$i);
            push @order, [ $col => $dir ];
        }
    }
    return @order;
}

=head2 _build_where_param
Convert a DataTables URI to a 'where' clause
=cut
sub _build_where_param {
    my ($self,$q) = @_;
    $self->{logger}->debug("_build_order_param: convert DataTables URI to a 'where' clause");
    my @where;
    if( defined $q->query_param('sSearch') ) {
        my $search_string = $q->query_param('sSearch');
        for( my $i = 0; $i < $q->query_param('iColumns'); $i++ ) {
            # Iterate over each column and check if it is searchable.
            # If so, add a constraint to the where clause restricting the given
            # column. In the query, the column is identified by it's index, we
            # need to translates the index to the column name.
            my $searchable_ident = 'bSearchable_'.$i;
            if( length $search_string > 0 and
                    $q->query_param($searchable_ident) and
                    $q->query_param($searchable_ident) eq 'true' ) {
                my $column = $self->_fnColumnToField( $i );
                push @where, [ { "$column like" => "%$search_string%" } ];
            }
        }
    }
    return @where;
}

=head2 _fnColumnToField
Map a DataTables column to a UR::Object attribute
=cut
sub _fnColumnToField {
    my $self = shift;
    $self->{logger}->debug("_fnColumnToField: ERROR: must be provided by a subclass!");
    return;
}

=head2 _build_result_set
Get the set of Volumes represented by a DataTables query.
=cut
sub _build_result_set {
    my $self = shift;
    $self->{logger}->debug("_build_result_set: ERROR: must be provided by a subclass!");
    return;
}

=head2 _build_aadata
Order and sort our UR::Object::Set as well as applying some modifiers and transformations.
=cut
sub _build_aadata {
    my $self = shift;
    $self->{logger}->debug("_build_aadata: ERROR: must be provided by a subclass!");
    return;
}

=head2 _prettify_aadata
Base prettify does nothing.  Define in a subclass to modify aadata.
=cut
sub _prettify_aadata {
    my $self = shift;
    return @_;
}

=head2 _sorter
Apply an 'order' clause to an array of arrays
=cut
sub _sorter {
    my $self = shift;
    $self->{logger}->debug("_sorter: apply an 'order' clause to an array of arrays");
    my $query = shift;
    return @_ unless @_;
    my @data = @_;
    # Implement Set ordering here, note that the Web UI (DataTables) supports
    # multi column sort, which is nice with direct DB call, but here we must
    # sort UR::Object::Sets which are by definition unordered.  Just do one column sort.
    my @order = $self->_build_order_param($query);
    return @data unless @order;
    my ($order_col,$order_dir) = @{ $order[0] };

    if (defined $order_dir and defined $order_col) {
        if ($order_dir eq 'asc') {
            # sort ascending
            if ( $data[0][ $order_col ] =~ /^\d+$/ ) {
                # numeric
                @data = sort { $a->[ $order_col ] <=> $b->[ $order_col ] } @data;
            } else {
                # non-numeric
                @data = sort { $a->[ $order_col ] cmp $b->[ $order_col ] } @data;
            }
        } else {
            # sort descending
            if ( $data[0][ $order_col ] =~ /^\d+$/ ) {
                # numeric
                @data = sort { $b->[ $order_col ] <=> $a->[ $order_col ] } @data;
            } else {
                # non-numeric
                @data = sort { $b->[ $order_col ] cmp $a->[ $order_col ] } @data;
            }
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
