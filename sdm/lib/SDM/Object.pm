package SDM::Object;

use strict;
use warnings;

use SDM;

=head1 class SDM::Object
This is an abstract base class used for generic Set views.
See sdm-service/lib/SDM/Object/Set/View/...
=cut
class SDM::Object {
    is => 'UR::Object',
    is_abstract => 1
};

1;
