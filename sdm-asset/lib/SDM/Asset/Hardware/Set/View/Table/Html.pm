
package SDM::Asset::Hardware::Set::View::Table::Html;

use strict;
use warnings;

use SDM;

class SDM::Asset::Hardware::Set::View::Table::Html {
    is => 'UR::Object::View::Default::Html'
};

=head2 _generate_content
This returns an HTML page we store elsewhere relative to this module tree.
=cut
sub _generate_content {
    my $self = shift;
    __FILE__ =~ /^(.*\/SDM\/).*/;
    my $base = $1;
    my $html = $base . "/View/Resource/Html/html/hardwaretable.html";
    open(FH,"<$html") or die "Failed to open $html: $!";
    my $content = do { local $/; <FH> };
    close(FH);
    return $content;
}

1;
