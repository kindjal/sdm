
package SDM::Asset::Software::Set::View::Table::Html;

=head2 SDM::Asset::Software::Set::View::Table::Html
Here select which Software attributes are included in Html view.
This must match those in the peer Json.pm class if the Html view is to make sense.
=cut
class SDM::Asset::Software::Set::View::Table::Html {
    is => "SDM::Object::Set::View::Table::Html",
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
