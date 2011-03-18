
package System::Disk::Volume::View::Summary::Cgi;

use strict;
use warnings;

use System;
use System::Disk::View::Lib qw( short commify );

use JSON;
use URI;
use URI::QueryParam;

sub new {
    my ($class,@args) = @_;
    my $self = {};
    bless $self,$class;
    return $self;
}

sub _fnColumnToField {
    my $self = shift;
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

sub _build_order_param {
    # FIXME: UR does not have ASC and DESC, it's always ASC
    my ($self,$q) = @_;
    my @order;
    if( defined $q->query_param('iSortCol_0') ){
        for( my $i = 0; $i < $q->query_param('iSortingCols'); $i++ ) {
            # We only get the column index (starting from 0), so we have to
            # translate the index into a column name.
            my $column_name = $self->_fnColumnToField( $q->query_param('iSortCol_'.$i) );
            my $direction = $q->query_param('sSortDir_'.$i);
            push @order, "$column_name $direction";
        }
    }
    return @order;
}

sub _build_where_param {
    my ($self,$q) = @_;
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

sub _build_result_set {
    # This requires UR beyond 94fbaa5086fc252078d2c25f368468bc76605e14
    # to support the -or clause.
    # FIXME: we still want LIMIT and OFFSET.
    my ($self,$q) = @_;
    my $param = {};

    # FIXME: UR returns a list of Volumes instead of a Set if I include @where
    #my @where = $self->_build_where_param($q);
    #if (scalar @where) {
    #    $param->{ -or } = \@where;
    #}

    # FIXME: UR order-by seems broken and doesn't do DESC
    #my @order = $self->_build_order_param($q);
    #if (scalar @order) {
    #    $param->{ -order_by } = \@order;
    #}

    # FIXME: UR: Bug: order-by and group-by broken?
    my $set = System::Disk::Volume->define_set( $param );
    my @result = $set->group_by( 'disk_group' );

    return @result;
}

sub run {

    my ($self,$args) = @_;

    my $json = new JSON;
    my $query = URI->new( $args->{REQUEST_URI} );
    my @results = $self->_build_result_set( $query );
    my $disk_group = {};

    # FIXME: This could go away if UR did sum() and order/group right.
    foreach my $result ( @results ) {
        my $name;
        my $total_kb = 0;
        my $used_kb = 0;
        my $capacity = 0;
        foreach my $item ( $result->members ) {
            my $name = $item->disk_group;
            $disk_group->{$name} = {}
                unless ($disk_group->{$name});
            $disk_group->{$name}->{total_kb} += $item->total_kb;
            $disk_group->{$name}->{used_kb} += $item->used_kb;
            if ( $disk_group->{$name}->{total_kb} ) {
                $disk_group->{$name}->{capacity} = sprintf("%d %%", $disk_group->{$name}->{used_kb} / $disk_group->{$name}->{total_kb} * 100);
            }
        }
    }
    # Now sort and prettify
    my @order = $self->_build_order_param($query);
    # FIXME: for now, single column sort
    my ($order,$direction) = split(' ',$order[0]);
    my @keys = sort { $disk_group->{$a}->{$order} <=> $disk_group->{$b}->{$order} } keys %$disk_group;
    if ($direction eq 'desc') {
        @keys = reverse @keys;
    }
    my @data;
    my @aaData;
    foreach my $name ( @keys ) {
        push @aaData, [
            $name,
            System::Disk::View::Lib::commify($disk_group->{$name}->{total_kb}) . " (" . System::Disk::View::Lib::short($disk_group->{$name}->{total_kb}) . ")",
            System::Disk::View::Lib::commify($disk_group->{$name}->{used_kb}) . " (" . System::Disk::View::Lib::short($disk_group->{$name}->{used_kb}) . ")",
            $disk_group->{$name}->{capacity}
        ];
    }

    # Implement limit and offset here to make up for lack of feature in get();
    sub max ($$) { int($_[ $_[0] < $_[1] ]) };
    sub min ($$) { int($_[ $_[0] > $_[1] ]) };
    my $limit  = $query->query_param('iDisplayLength') || 10;
    my $offset = $query->query_param('iDisplayStart') || 0;
    my @group_totals = @results[$offset..min($limit,$#results)];

    my $sEcho = defined $query->query_param('sEcho') ? $query->query_param('sEcho') : 1;
    my $iTotal = scalar @results;
    my $iFilteredTotal = scalar @group_totals;
    my $sOutput = {
        sEcho => $sEcho,
        iTotalRecords => int($iTotal),
        iTotalDisplayRecords => int($iFilteredTotal),
        aaData => \@aaData,
    };

    my $result = $json->encode($sOutput);
    return $result
}

1;
