
package Sdm::Value::KBytes;

class Sdm::Value::KBytes {
    is => 'UR::Value::Number',
};

sub __display_name__ {
    my $self = shift;
    my $value = $self->id;
    my $string = sprintf "%s (%s)", $self->_commify($value), $self->_short_form($value);
    return $string;
}

sub _short_form {
    my $self = shift;
    #$self->{logger}->debug("_short: convert number to abbreviated form");
    my $number = shift;
    return '' unless (defined $number);
    return $number unless ($number =~ /^[\d\.]+$/);

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

sub _commify {
    my $self = shift;
    #$self->{logger}->debug("_commify: add commas to long number");
    my $number = shift;
    return '' unless (defined $number);
    return $number unless ($number =~ /^[\d\.]+$/);
    # commify a number. Perl Cookbook, 2.17, p. 64
    my $text = reverse $number;
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

1;
