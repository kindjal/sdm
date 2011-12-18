
package Sdm::Disk::Fileset::Set::View::Table::Xml;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Fileset::Set::View::Table::Xml {
    is => 'UR::Object::Set::View::Default::Xml',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'xml',
                    subject_class_name => 'Sdm::Disk::Fileset',
                    aspects => [
                        'mount_path',
                        'total_kb',
                        'used_kb',
                        'capacity',
                        'disk_group',
                        'filername',
                        'last_modified',
                    ]
                }
            ]
        }
    ]
};

1;
