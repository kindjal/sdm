
package System::Disk::View::Status::Html;

use strict;
use warnings;

use System;

class System::Disk::View::Status::Html {
    is => 'UR::Object::View::Default::Html'
};

# This is the full view of Disk Usage
# FIXME: This returns an HTML page we store in a file elsewhere.
sub _generate_content {
    my $self = shift;
    __FILE__ =~ /^(.*\/System\/).*/;
    my $base = $1;
    my $html = $base . "/View/Resource/Html/html/diskusage.html";
    open(FH,"<$html") or die "Failed to open $html: $!";
    my $content = do { local $/; <FH> };
    close(FH);
    return $content;
}

1;
