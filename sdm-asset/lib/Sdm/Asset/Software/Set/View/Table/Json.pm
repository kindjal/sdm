
package Sdm::Asset::Software::Set::View::Table::Json;

=head2 Sdm::Asset::Software::Set::View::Table::Json
Here select which Software attributes are included in Json view.
This must match those in the peer Html.pm class if the Html view is to make sense.
=cut
class Sdm::Asset::Software::Set::View::Table::Json {
    is => "Sdm::Object::Set::View::Table::Json",
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                        'id',
                        'manufacturer',
                        'product',
                        'license',
                        'description',
                        'comments',
                        'seats',
                        'created',
                        'last_modified'
            ]
        }
    ]
};

1;
