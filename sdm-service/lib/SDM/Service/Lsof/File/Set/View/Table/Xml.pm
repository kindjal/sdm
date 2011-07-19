
package SDM::Service::Lsof::File::Set::View::Table::Xml;

use strict;
use warnings;

use SDM;

class SDM::Service::Lsof::File::Set::View::Table::Xml {
    is => 'UR::Object::Set::View::Default::Xml',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'xml',
                    subject_class_name => 'SDM::Service::Lsof::File',
                    aspects => [
                        'hostname',
                        'pid',
                        'filename',
                        #'created',
                        #'last_modified'
                    ]
                }
            ]
        }
    ]
};

1;
