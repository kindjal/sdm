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
    my $html = System->base_dir . "/View/Resource/Html/html/volumetable.html";
    open(FH,"<$html") or die "Failed to open $html: $!";
    my $content = do { local $/; <FH> };
    close(FH);
    return $content;
}

1;
