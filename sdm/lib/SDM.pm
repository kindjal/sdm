
package SDM;

use warnings;
use strict;

use SDM::Site;
use UR;

our $VERSION = "0.03";

class SDM {
    is => [ 'UR::Namespace' ],
};

for my $dir (@INC) {
    if (-d "$dir/SDM/Env" ) {
        foreach my $mod ( glob($dir . '/SDM/Env/*') ) {
            require $mod;
        }
    }
}

# SDM supports several environment variables, found under SDM/ENV
# Any SYSTEM_* variable which is set but does NOT corresponde to a module found will cause an exit
# (a hedge against typos such as SYSTEM_DATABASE_DDDRIVER=1 leading to unexpected behavior)
for my $e (keys %ENV) {
    next unless substr($e,0,7) eq 'SYSTEM_';
    eval "use SDM::Env::$e";
    if ($@) {
        my $path = __FILE__;
        $path =~ s/.pm$//;
        my @files = glob($path . '/Env/*');
        my @vars = map { /SDM\/Env\/(.*).pm/; $1 } @files; 
        print STDERR "Environment variable $e set to $ENV{$e} but there were errors using SDM::Env::$e:\n$@"
        . "Available variables:\n\t" 
        . join("\n\t",@vars)
        . "\n";
        exit 1;
    }
}

sub _doc_manual_body {
    return <<EOS
The SDM suite is a UR Namespace and includes tools to manage and model Linux systems.
EOS
}

sub _doc_copyright_years {
    (2011);
}

sub _doc_license {
    my $self = shift;
    my (@y) = $self->_doc_copyright_years;
    return <<EOS
Copyright (C) $y[0]-$y[1] Washington University in St. Louis.

It is released under the Lesser GNU Public License (LGPL) version 3.  See the
associated LICENSE file in this distribution.
EOS
}

sub _doc_authors {
    return (
        <<EOS,
This software is developed by the software engineering team at
The Genome Institute at Washington University School of Medicine in St. Louis,
with funding from the National Human Genome Research Institute.  Richard K. Wilson, P.I.

The primary author(s) of the SDM suite are:
EOS
        'Matthew Callaway <mcallawa@genome.wustl.edu>',
    );
}


sub _doc_bugs {
    # FIXME: update email
    return <<EOS;
For defects with any software in the genome namespace, contact
 sdm-dev ~at~ genome.wustl.edu.
EOS
}

sub _doc_credits {
    # FIXME: Update
    return <<EOS;
    TBD
EOS
}

sub _doc_see_also {
    'B<sdm>(1)',
}

1;
