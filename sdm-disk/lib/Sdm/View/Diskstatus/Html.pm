
package Sdm::View::Diskstatus::Html;

# We need to keep the "object" or the "subject" of the query that happens in
# Rest.psgi to just the namespace singleton, so that we aren't actually going
# to ask the database for objects.  The stuff after the "View" is descriptive
# of the thing we're trying to display, in this case a disk dashboard that is
# an HTML document containing javascript that performs Ajax queries to get more
# detailed sets of objects.

use strict;
use warnings;

use Sdm;

class Sdm::View::Diskstatus::Html {
    is => 'UR::Object::View::Default::Html'
};

=head2 _generate_content
This returns an HTML page we store elsewhere relative to this module tree.
=cut
sub _generate_content {
    my $self = shift;
    warn "base: " . Sdm->base_dir;
    __FILE__ =~ /^(.*\/Sdm\/).*/;
    my $base = $1;
    my $html = $base . "/Service/WebApp/public/diskstatus.html";
    open(FH,"<$html") or die "Failed to open $html: $!";
    my $content = do { local $/; <FH> };
    close(FH);
    return $content;
}

1;
