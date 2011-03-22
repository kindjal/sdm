
package System::Disk::Filer::View::Summary::Cgi;

use strict;
use warnings;

use System;
use System::Disk::View::Lib qw( short commify );

use Date::Manip;
use JSON;
use URI;
use URI::QueryParam;

sub new {
    my ($class,$args) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub run {

    my ($self,$args) = @_;

    my $json = new JSON;
    my @aaData;

    my $query = URI->new( $args->{REQUEST_URI} );

    # FIXME: I want to parse the set of all volumes per filer.
    #my @results = $self->_build_result_set( $query );
    my $result = { total_kb => 0, used_kb => 0, last_modified => '0000:00:00:00:00:00' };

    foreach my $r ( System::Disk::Volume->get() ) {
        $result->{total_kb} += $r->{total_kb};
        $result->{used_kb} += $r->{used_kb};
        $result->{last_modified} = $r->{last_modified} ? $r->{last_modified} : $result->{last_modified};

        # FIXME: super slow
        #my $date0 = Date::Manip::Date->new();
        #my $date1 = Date::Manip::Date->new();
        #my $mod = $r->{last_modified} ? $r->{last_modified} : '0000:00:00:00:00:00';
        #$mod =~ s/[ -]/:/g;
        #$date0->parse( $result->{last_modified} );
        #$date1->parse( $mod );
        #$result->{last_modified} = $r->{last_modified} if ( $date0->cmp($date1));
    }

    $result->{capacity} = 0;
    if ($result->{total_kb}) {
        $result->{capacity} = sprintf "%d %%", $result->{used_kb} / $result->{total_kb} * 100;
    }
    $result->{total_kb} = System::Disk::View::Lib::commify($result->{total_kb}) . " (" . System::Disk::View::Lib::short($result->{total_kb}) . ")",
    $result->{used_kb} = System::Disk::View::Lib::commify($result->{used_kb}) . " (" . System::Disk::View::Lib::short($result->{used_kb}) . ")",

    return $json->encode($result);
}

1;
