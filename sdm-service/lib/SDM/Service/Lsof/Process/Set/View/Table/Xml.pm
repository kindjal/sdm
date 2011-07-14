
package SDM::Service::Lsof::Process::Set::View::Table::Xml;

use strict;
use warnings;

use SDM;

class SDM::Service::Lsof::Process::Set::View::Table::Xml {
    is => 'UR::Object::Set::View::Default::Xml',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'xml',
                    subject_class_name => 'SDM::Service::Lsof::Process',
                    aspects => [
                        'hostname',
                        'pid',
                        'command',
                        'username',
                        'uid',
                        'age',
                        'filename',
                        #{
                        #    name => 'files',
                        #    aspects => [
                        #        'filename',
                        #    ],
                        #    perspective => 'default',
                        #    toolkit => 'xml',
                        #    subject_class_name => 'SDM::Service::Lsof::File',
                        #},
                        'created',
                        'last_modified'
                    ]
                }
            ]
        }
    ]
};

1;
