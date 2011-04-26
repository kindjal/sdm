
package System::Disk::Volume::View::Summary::Cgi;

use strict;
use warnings;

use System;
use System::Disk::View::Lib qw( short commify );

use JSON;
use URI;
use URI::QueryParam;

class System::Disk::Volume::View::Summary::Cgi {
    is => 'System::Command::Base',
};

#sub new {
#    my ($class,@args) = @_;
#    my $self = {};
#    bless $self,$class;
#    return $self;
#}

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

sub _build_order_param0 {
    my ($self,$q) = @_;
    $self->{logger}->debug("_build_order_param0");
    my @order;
    if( defined $q->query_param('iSortCol_0') ){
        for( my $i = 0; $i < $q->query_param('iSortingCols'); $i++ ) {
            # We only get the column index (starting from 0), so we have to
            # translate the index into a column name.
            my $column_name = $self->_fnColumnToField( $q->query_param('iSortCol_'.$i) );
            my $direction = $q->query_param('sSortDir_'.$i);
            if ($direction eq 'desc') {
                $column_name = "-$column_name";
            } elsif ($direction eq 'asc') {
                $column_name = "+$column_name";
            }
            push @order, $column_name;
        }
    }
    return @order;
}

sub _build_order_param {
    my ($self,$q) = @_;
    $self->{logger}->debug("_build_order_param");
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

sub _build_where_param {
    my ($self,$q) = @_;
    $self->{logger}->debug("_build_where_param");
    my @where;
    if ( defined $q->query_param('sSearch') ) {
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

sub _build_result_set {
    my ($self,$q) = @_;
    my $param = $self->_build_query_param($q);
    $self->{logger}->debug("_build_result_set: " . Data::Dumper::Dumper $param);
    my @results = System::Disk::Volume->get( $param );
    return @results;
}

sub _build_aadata {
    my $self = shift;
    $self->{logger}->debug("_build_aadata");
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

sub _prettify_aadata {
    my $self = shift;
    $self->{logger}->debug("_prettify_aadata");
    my @data = @_;
    return [] unless @data;
    @data = map { [
         $_->[0],
         System::Disk::View::Lib::commify($_->[1]) . " (" . System::Disk::View::Lib::short($_->[1]) . ")",
         System::Disk::View::Lib::commify($_->[2]) . " (" . System::Disk::View::Lib::short($_->[2]) . ")",
         sprintf("%d %%", $_->[3]),
       ] } @data;
    return @data;
}

sub run {

    # $uri comes from CGI.psgi in web-app
    my ($self,$uri) = @_;
    $self->{logger}->debug("run: $uri");

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
