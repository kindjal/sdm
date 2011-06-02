
package SDM::Disk::Array::Set::View::Table::Json;

use strict;
use warnings;

use SDM;

class SDM::Disk::Array::Set::View::Table::Json {
    is => 'UR::Object::Set::View::Default::Json',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'json',
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
