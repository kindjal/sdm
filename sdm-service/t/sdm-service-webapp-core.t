
use strict;
use warnings;

use Test::More;
use DBI;

use above 'SDM';

our @dbi_classes = ();

sub my_connect {
    my $i = 1;
    while (1) {
        my @caller = caller($i++);
        last unless @caller;
        if ($caller[0] =~ /^SDM/) {
            push @dbi_classes, $caller[0];
            last;
        }
    }

    shift->real_connect(@_);
}

*DBI::real_connect = *DBI::connect;
*DBI::connect = *main::my_connect;

0 && &DBI::real_connect; # prevents warning

use_ok('SDM::Service::WebApp::Core');

foreach my $c (@SDM::Service::WebApp::Core::error_classes) {
    diag('Error loading: ' . $c);
}
ok(scalar @SDM::Service::WebApp::Core::error_classes == 0, 'no errors loading classes');

foreach my $c (@dbi_classes) {
    diag('DBI->connect while loading: ' . $c);
}
ok(scalar @dbi_classes == 0, 'no classes caused DBI connect during loading');

done_testing();
