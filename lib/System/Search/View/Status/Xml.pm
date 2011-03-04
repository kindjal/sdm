
package System::Search::View::Status::Xml;

use strict;
use warnings;

class System::Search::View::Status::Xml {
    is => 'UR::Object::View::Default::Xml',
    has_constant => [
        perspective => 'status',
        toolkit => 'xml',
        default_aspects => {
            value => []
        }
    ]
};

1;
