use strict;
use warnings;

use System;
use Data::Dumper;

package System::Disk::Filer::View::Default::Html;

class System::Disk::Filer::View::Default::Html {
    is => 'UR::Object::View::Default::Html'
};

sub _generate_content {
    my $self = shift;
    my $f = System::Disk::Filer->get( name => 'nfs11' );
    my $content = sprintf "%s", Data::Dumper::Dumper $f;
    return "<html><pre>$content</pre></html>";
}

1;
