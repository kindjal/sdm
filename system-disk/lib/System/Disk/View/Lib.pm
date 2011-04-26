
package System::Disk::View::Lib;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(short commify);

use URI;
use URI::QueryParam;

sub short {
    my $number = shift;
    return unless (defined $number and $number =~ /^\d+$/);

    my $cn = commify($number);
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
    my $number = shift;
    return $number unless (defined $number and $number =~ /^\d+$/);
    # commify a number. Perl Cookbook, 2.17, p. 64
    my $text = reverse $number;
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

1;
