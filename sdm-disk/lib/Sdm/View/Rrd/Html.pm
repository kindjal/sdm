
package Sdm::View::Rrd::Html;

use strict;
use warnings;

use Sdm;

class Sdm::View::Rrd::Html {
    is => 'UR::Object::View::Default::Html'
};

=head2 _generate_content
This returns an HTML page for a disk group status RRD trend graph.
This is part of Diskstatus/Html.pm.
=cut
sub _generate_content {
    my $self = shift;
    #__FILE__ =~ /^(.*\/Sdm\/).*/;
    #my $base = $1;
    #my $html = $base . "/Service/WebApp/public/rrd.html";
    my $html = Sdm->base_dir . "/public/rrd.html";
    open(FH,"<$html") or die "Failed to open $html: $!";
    my $content = do { local $/; <FH> };
    close(FH);
    return $content;
}

1;
