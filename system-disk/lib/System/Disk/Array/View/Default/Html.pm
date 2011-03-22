use strict;
use warnings;

use System;
use Data::Dumper;

package System::Disk::Array::View::Default::Html;

class System::Disk::Array::View::Default::Html {
    is => 'UR::Object::View::Default::Html'
};

sub _generate_content {
    my $self = shift;
    #my $f = System::Disk::Array->get()
    #my $content = sprintf "%s", Data::Dumper::Dumper $f;
    #return "<html><pre>hi</pre></html>";
}

1;
