
package System::Disk::Filer::Set;

use System;
use Data::Dumper;

class System::Disk::Filer::Set {
    is => 'UR::Object::Set',
    has => [
        aaData               => { is => 'ARRAY', is_many => 1 },
        iTotalRecords        => { is => 'Number' },
        iTotalDisplayRecords => { is => 'Number' },
        sEcho                => { is => 'Number' },
    ],
};

sub iTotalRecords {
    my $self = shift;
    my @s = $self->members;
    return $#s;
}

sub iTotalDisplayRecords {
    my $self = shift;
    my @s = $self->members;
    return $#s;
}

sub aaData {
    my $self = shift;
    my @data;
    foreach my $item ( $self->members ) {
        my $hostname = 'unknown';
        my @hosts = $item->hostname;
        if (@hosts) {
            $hostname = join(",",@hosts);
        }
        my $arrayname = 'unknown';
        my @arrays = $item->arrayname;
        if (@arrays) {
            $arrayname = join(",",@arrays);
        }

        push @data, [
            $item->{name},
            $item->{status},
            $hostname,
            $arrayname,
            $item->{created} ? $item->{created} : "0000-00-00 00:00:00",
            $item->{last_modified} ? $item->{last_modified} : "0000-00-00 00:00:00",
        ];
    }
    return @data;
}

sub sEcho {
    my $self = shift;
    return 1;
}

1;
