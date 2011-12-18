
package Sdm::Service::Lsof::File::Set::View::Table::Xml;

use strict;
use warnings;

use Sdm;

class Sdm::Service::Lsof::File::Set::View::Table::Xml {
    is => 'UR::Object::Set::View::Default::Xml',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'xml',
                    subject_class_name => 'Sdm::Service::Lsof::File',
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
