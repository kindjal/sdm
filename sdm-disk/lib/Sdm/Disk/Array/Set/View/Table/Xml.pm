
package Sdm::Disk::Array::Set::View::Table::Xml;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Array::Set::View::Table::Xml {
    is => 'UR::Object::Set::View::Default::Xml',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'xml',
                    subject_class_name => 'Sdm::Disk::Array',
                    aspects => [
                        'name',
                        'manufacturer',
                        'model',
                        'serial',
                        'hostname',
                        'arraysize',
                        'created',
                        'last_modified'
                    ]
                }
            ]
        }
    ]
};

1;
