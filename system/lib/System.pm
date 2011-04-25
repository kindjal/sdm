
package System;

use warnings;
use strict;

use System::Site;
use UR;

class System {
    is => [ 'UR::Namespace' ],
};

sub _doc_manual_body {
    return <<EOS
The System suite is a UR Namespace and includes tools to manage and model Linux systems.
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

The primary author(s) of the System suite are:
EOS
        'Matthew Callaway <mcallawa@genome.wustl.edu>',
    );
}


sub _doc_bugs {
    return <<EOS;
For defects with any software in the genome namespace, contact
 system-dev ~at~ genome.wustl.edu.
EOS
}

sub _doc_credits {
    # FIXME: Update
    return <<EOS;
    TBD
EOS
}

sub _doc_see_also {
    'B<system>(1)',
}

1;
