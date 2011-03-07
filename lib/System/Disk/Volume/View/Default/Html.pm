use strict;
use warnings;

use System;
use Data::Dumper;

package System::Disk::Volume::View::Default::Html;

class System::Disk::Volume::View::Default::Html {
    is => 'UR::Object::View::Default::Html'
};

sub _generate_content {
    my $self = shift;
    open(FH,"<volumetable.html") or die "Failed to open volumetable.html: $!";
    my $content = <FH>;
    close(FH);
    return "<html>hi</html>":
    #return $content;
}

1;
