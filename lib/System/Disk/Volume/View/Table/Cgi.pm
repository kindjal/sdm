
package System::Disk::Volume::View::Table::Cgi;

use strict;
use warnings;

use System;

use JSON;
use URI;
use URI::QueryParam;

sub new {
    my ($class,@args) = @_;
    my $self = {};
    bless $self,$class;
    return $self;
}

sub _get_total_record_count {
    return 1;
}

sub _get_filtered_record_count {
    return 1;
}

sub short {
  my $self = shift;
  my $number = shift;

  my $cn = $self->commify($number);
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

sub commify {
  my $self = shift;
  my $number = shift;
  # commify a number. Perl Cookbook, 2.17, p. 64
  my $text = reverse $number;
  $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
  return scalar reverse $text;
}

sub _fnColumnToField {
  my $self = shift;
  my $i = shift;

  # Note: we could have used an array, but for dispatching purposes, this is
  # more readable.
  my %dispatcher = (
    # column => 'rowname',
    0 => 'mount_path',
    1 => 'physical_path',
    2 => 'total_kb',
    3 => 'used_kb',
    4 => 'capacity',
    5 => 'filername',
    6 => 'disk_group',
    7 => 'last_modified',
  );

  die("No such row index defined: $i") unless exists $dispatcher{$i};

  return $dispatcher{$i};
} # /_fnColumnToField

sub _generate_where_clause {
  my $self = shift;
  my $q = shift;

  my @where;

  if( defined $q->query_param('sSearch') ) {
    my $search_string = $q->query_param('sSearch');
    for( my $i = 0; $i < $q->query_param('iColumns'); $i++ ) {
      # Iterate over each column and check if it is searchable.
      # If so, add a constraint to the where clause restricting the given
      # column. In the query, the column is identified by it's index, we
      # need to translates the index to the column name.
      my $searchable_ident = 'bSearchable_'.$i;
      #if( $q->query_param($searchable_ident) and $q->query_param($searchable_ident) eq 'true' ) {
      if( length $search_string > 0 and
          $q->query_param($searchable_ident) and
          $q->query_param($searchable_ident) eq 'true' ) {
        my $column = $self->_fnColumnToField( $i );
        push @where,"$column LIKE \"%%$search_string%%\"";
      }
    }
  }

  my $where;
  $where .= " WHERE " . join(" OR ",@where) if (@where);
  return $where;
} # /_generate_where_clause

sub _generate_order_clause {
  my $self = shift;
  my $q = shift;

  my @order = ();
  if( defined $q->query_param('iSortCol_0') ){
    for( my $i = 0; $i < $q->query_param('iSortingCols'); $i++ ) {
      # We only get the column index (starting from 0), so we have to
      # translate the index into a column name.
      my $column_name = $self->_fnColumnToField( $q->query_param('iSortCol_'.$i) );
      my $direction = $q->query_param('sSortDir_'.$i);
      push @order, "$column_name $direction";
    }
  }

  my $order;
  $order .= " ORDER BY " . join(',',@order) if (@order);
  return $order;
} # /_generate_order_clause

sub _build_sql_select {
    my ($self,$query) = @_;

    # FIXME: UR defaults to an AND query and we want this to be an OR query.
    # So we build our own SQL.
    my $select = "SELECT mount_path, physical_path, total_kb, used_kb, ROUND((CAST(used_kb AS REAL)/total_kb * 100),2) as capacity, filername, disk_group, last_modified FROM disk_volume";

    # -- Filtering: applies DataTables search box
    my $where = $self->_generate_where_clause($query);
    if ($where) {
        $select .= $where;
    }

    # -- Ordering: makes DataTables column sorting work
    my $order = $self->_generate_order_clause($query);
    if ($order) {
        $select .= $order;
    }

    # -- Paging
    my $paging;
    my $limit = $query->query_param('iDisplayLength') || 10;
    if ($limit) {
        $paging .= " LIMIT $limit";
    }
    my $offset = 0;
    if( $query->query_param('iDisplayStart') ) {
        $offset = $query->query_param('iDisplayStart');
    }
    if ($offset) {
        $paging .= " OFFSET $offset";
    }
    $select .= $paging;
    return $select;
}

sub run {

    my ($self,$args) = @_;

    my $json = new JSON;
    my @aaData;

    my $query = URI->new( $args->{REQUEST_URI} );

    # UR Missing feature: Can't to OR clauses in get()
    # So try building SQL for get()
    # UR BUG: duplicate data somehow?
    my @vols = System::Disk::Volume->get( sql => $self->_build_sql_select( $query ) );
    # Next try:
    # 1 get() for each searchable column
    # build the hash with key of object id in result set
    foreach my $v (@vols) {
        push @aaData, [
            $v->{mount_path},
            $v->{physical_path},
            $self->commify($v->{total_kb}) . " (" . $self->short($v->{total_kb}) . ")",
            $self->commify($v->{used_kb}) . " (" . $self->short($v->{used_kb}) . ")",
            sprintf("%d %%", $v->{capacity} ? $v->{capacity} : 0 ),
            $v->{filername},
            $v->{disk_group} ? $v->{disk_group} : 'unknown',
            $v->{last_modified} ? $v->{last_modified} : 'unknown'
        ];
    }

    my $sEcho = defined $query->query_param('sEcho') ? $query->query_param('sEcho') : 1;
    # FIXME: find total?
    my @results = System::Disk::Volume->get();
    my $iTotal = scalar @results;
    warn "DEBUG total $iTotal\n";
    my $iFilteredTotal = scalar @vols;
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
