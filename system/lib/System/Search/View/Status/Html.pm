use strict;
use warnings;

use System;
use Data::Dumper;

package System::Search::View::Status::Html;

class System::Search::View::Status::Html {
    is => 'UR::Object::View::Default::Html'
};

sub _generate_content {
    my $self = shift;
    return "<html>Search Content</html>";
}

1;
