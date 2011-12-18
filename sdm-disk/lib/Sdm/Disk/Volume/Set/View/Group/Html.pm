
package Sdm::Disk::Volume::Set::View::Group::Html;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Volume::Set::View::Group::Html {
    is => 'UR::Object::View::Default::Html'
};

=head2 _generate_content
This returns an HTML page we store elsewhere relative to this module tree.
=cut
sub _generate_content {
    my $self = shift;
    __FILE__ =~ /^(.*\/Sdm\/).*/;
    my $base = $1;
    my $html = $base . "/View/Resource/Html/html/groupvolumetable.html";
    open(FH,"<$html") or die "Failed to open $html: $!";
    my $content = do { local $/; <FH> };
    close(FH);
    return $content;
}

1;
