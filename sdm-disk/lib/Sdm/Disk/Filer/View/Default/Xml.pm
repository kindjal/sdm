
package Sdm::Disk::Filer::View::Default::Xml;

class Sdm::Disk::Filer::View::Default::Xml {
    is => 'UR::Object::View::Default::Xml',
    has_constant => [
        perspective => {
            value => 'default',
        },
        default_aspects => {
            is => 'ARRAY',
            value => [
                'name',
                'status',
                'comments',
                'created',
                'last_modified',
                'host',
                'arrayname',
            ],
        },
    ],
};

1;
