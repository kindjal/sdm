use strict;
use warnings;

use System;

package System::Disk::Volume::View::Table::Html;

sub new {
    my ($class,$args) = @_;
    my $self = {};
    bless $self,$class;
    return $self;
}

sub _generate_content {
    my $self = shift;
    my $html = System->base_dir . "/View/Resource/Html/html/volumetable.html";
    open(FH,"<$html") or die "Failed to open $html: $!";
    my $content = do { local $/; <FH> };
    close(FH);
    return $content;
}

1;
