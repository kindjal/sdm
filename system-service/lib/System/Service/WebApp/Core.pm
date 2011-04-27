package System::Service::WebApp::Core;

# loads the majority of the base system used (not tools)

use File::Find;
use System;

our @error_classes;
my $imported = 0;
sub import {
    return 1 if $imported;
    $imported = 1;
    my @classes = ();

    my $base_dir = System->base_dir;
    find(
        sub {
            return if (index($_,'Test.pm') == 0);
            return if (index($_,'.pm') < 0 || index($_,'.pm') != length($_) - 3);
            my $name = 'System' . substr($File::Find::name,length($base_dir));

            $name =~ s/\//::/g;
            substr($name,index($name,'.pm'),3,'');

            push @classes, $name;
        },
        $base_dir
    );

    @error_classes = grep {
        my $r = 0;
        $r;
    } @classes;

    warn "The following classes loaded with errors:\n  " .
        join ("\n  ",@error_classes)
        if (@error_classes);
    1;
}

1;
