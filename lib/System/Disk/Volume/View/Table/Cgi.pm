
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

sub run {

    my ($self,$args) = @_;

    my $json = new JSON;

    my $query = URI->new($args->{REQUEST_URI});
    my $param = $query->query_param;

    # FIXME: Build params based on query string search terms
    my @aaData;
    #my $params;
    foreach my $v (System::Disk::Volume->get( )) {
        my $mount_path = $v->{mount_path};
        my $physical_path = $v->{physical_path};
        my $total_kb = $v->{total_kb} ? $v->{total_kb} : 0;
        my $used_kb = $v->{used_kb} ? $v->{used_kb} : 0;

        my $percentage = 0;
        if ( $used_kb > 0 and $total_kb > 0 ) {
            $percentage = sprintf "%d %", $used_kb / $total_kb * 100;
        }
        $total_kb = $self->commify($total_kb) . " (" . $self->short($total_kb) . ")";
        $used_kb = $self->commify($used_kb) . " (" . $self->short($used_kb) . ")";

        my $disk_group = $v->{disk_group} ? $v->{disk_group} : 'unknown';
        my $last_modified = $v->{last_modified} ? $v->{last_modified} : 'unknown';

        push @aaData, [$mount_path,$physical_path,$total_kb,$used_kb,$percentage,$disk_group,$last_modified];
    }

    my $sEcho = defined $query->query_param('sEcho') ? $query->query_param('sEcho') : 1;
    my $iTotal = $self->_get_total_record_count();
    my $iFilteredTotal = $self->_get_filtered_record_count();
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
