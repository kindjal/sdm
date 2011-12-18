use strict;
use warnings;

use Sdm;
use Data::Dumper;

package Sdm::Disk::Array::View::Default::Html;

class Sdm::Disk::Array::View::Default::Html {
    is => 'UR::Object::View::Default::Html'
};

sub _generate_content {
    my $self = shift;
    #my $f = Sdm::Disk::Array->get()
    #my $content = sprintf "%s", Data::Dumper::Dumper $f;
    #return "<html><pre>hi</pre></html>";
}

1;
