
package SDM::Disk::Host::Set::View::Table::Xml;

use strict;
use warnings;

use SDM;

class SDM::Disk::Host::Set::View::Table::Xml {
    is => 'UR::Object::Set::View::Default::Xml',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'xml',
                    subject_class_name => 'SDM::Disk::Host',
                    aspects => [
                        'hostname',
                        'arrayname',
                        'filername',
                        'os',
                        'location',
                        'status',
                        'comments',
                        'created',
                        'last_modified'
                    ]
                }
            ]
        }
    ]
};

1;
