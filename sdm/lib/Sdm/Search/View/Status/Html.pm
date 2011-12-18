use strict;
use warnings;

use Sdm;
use Data::Dumper;

package Sdm::Search::View::Status::Html;

class Sdm::Search::View::Status::Html {
    is => 'UR::Object::View::Default::Html'
};

sub _generate_content {
    my $self = shift;
    return "<html>Search Content</html>";
}

1;
