
package SDM::Disk::Array::Set::View::Table::Xml;

use strict;
use warnings;

use SDM;

class SDM::Disk::Array::Set::View::Table::Xml {
    is => 'UR::Object::Set::View::Default::Xml',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'xml',
                    subject_class_name => 'SDM::Disk::Array',
                    aspects => [
                        'name',
                        'manufacturer',
                        'model',
                        'serial',
                        'disk_type',
                        'disk_num',
                        'arraysize',
                        'adv_arraysize',
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