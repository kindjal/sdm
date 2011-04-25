use strict;
use warnings;

use System;

package System::Disk::View::Status::Html;

sub new {
    my ($class,$args) = @_;
    my $self = {};
    bless $self,$class;
    return $self;
}

# This is the full view of Disk Usage
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
