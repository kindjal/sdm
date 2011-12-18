package Sdm::Object;

use strict;
use warnings;

use Sdm;

=head1 class Sdm::Object
This is an abstract base class used for generic Set views.
See sdm-service/lib/Sdm/Object/Set/View/...
=cut
class Sdm::Object {
    is => 'UR::Object',
    is_abstract => 1
};

1;
