
package Sdm::Disk::Array::Set::View::Table::Json;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Array::Set::View::Table::Json {
    is => 'UR::Object::Set::View::Default::Json',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'json',
                    subject_class_name => 'Sdm::Disk::Array',
                    aspects => [
                        'name',
                        'manufacturer',
                        'model',
                        'serial',
                        'arraysize',
                        'created',
                        'last_modified',
                        'hostname'
                    ]
                }
            ]
        }
    ]
};

1;
