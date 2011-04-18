
package System::Disk::Filer::View::Status::Cgi;

use strict;
use warnings;

use System;

use JSON;
use URI;
use URI::QueryParam;

sub new {
    my ($class,$args) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub _fnColumnToField {
    my $self = shift;
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
            push @order, "$column_name";
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
                push @where, { "$column like" => "%%$search_string%%" };
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
    my @where = $self->_build_where_param($q);
    my @order = $self->_build_order_param($q);
    if (scalar @where) {
        $param->{ -or } = [ \@where ];
    }
    # FIXME: UR order can't do DESC
    if (scalar @order) {
        $param->{ -order } = \@order;
    }
    my @result = System::Disk::Filer->get( $param );
    # Implement limit and offset here to make up for lack of feature in get();
    sub max ($$) { int($_[ $_[0] < $_[1] ]) };
    sub min ($$) { int($_[ $_[0] > $_[1] ]) };
    my $limit  = $q->query_param('iDisplayLength') || 10;
    my $offset = $q->query_param('iDisplayStart') || 0;
    my $ceiling = min($limit - 1,$#result);
    @result = @result[$offset..$ceiling];
    return @result;
}

sub run {

    my ($self,$args) = @_;

    my $json = new JSON;
    my @aaData;

    my $query = URI->new( $args->{REQUEST_URI} );

    my @filers = $self->_build_result_set( $query );
    foreach my $f ( @filers ) {
        my $hostname = 'unknown';
        my @hosts = $f->hostname;
        if ($#hosts) {
            $hostname = join(",",@hosts);
        }
        my $arrayname = 'unknown';
        my @arrays = $f->arrayname;
        if ($#arrays) {
            $arrayname = join(",",@arrays);
        }

        push @aaData, [
            $f->{name},
            $f->{status},
            $hostname,
            $arrayname,
            $f->{created} ?  $f->{created} : "0000-00-00 00:00:00",
            $f->{last_modified} ? $f->{last_modified} : "0000-00-00 00:00:00",
        ];
    }

    my $sEcho = defined $query->query_param('sEcho') ? $query->query_param('sEcho') : 1;
    my @results = System::Disk::Filer->get();
    my $iTotal = scalar @results;
    my $iFilteredTotal = scalar @filers;
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
