
package SDM::Service::Lsof::Process::Set::View::Table::Json;

use strict;
use warnings;

use SDM;

class SDM::Service::Lsof::Process::Set::View::Table::Json {
    is => 'UR::Object::Set::View::Default::Json',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'json',
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
                        #    toolkit => 'json',
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
