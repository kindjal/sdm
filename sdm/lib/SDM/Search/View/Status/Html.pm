use strict;
use warnings;

use SDM;
use Data::Dumper;

package SDM::Search::View::Status::Html;

class SDM::Search::View::Status::Html {
    is => 'UR::Object::View::Default::Html'
};

sub _generate_content {
    my $self = shift;
    return "<html>Search Content</html>";
}

1;
