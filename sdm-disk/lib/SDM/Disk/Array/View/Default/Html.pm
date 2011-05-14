use strict;
use warnings;

use SDM;
use Data::Dumper;

package SDM::Disk::Array::View::Default::Html;

class SDM::Disk::Array::View::Default::Html {
    is => 'UR::Object::View::Default::Html'
};

sub _generate_content {
    my $self = shift;
    #my $f = SDM::Disk::Array->get()
    #my $content = sprintf "%s", Data::Dumper::Dumper $f;
    #return "<html><pre>hi</pre></html>";
}

1;
