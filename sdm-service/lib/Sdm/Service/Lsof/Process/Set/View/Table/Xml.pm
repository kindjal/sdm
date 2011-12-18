
package Sdm::Service::Lsof::Process::Set::View::Table::Xml;

use strict;
use warnings;

use Sdm;

class Sdm::Service::Lsof::Process::Set::View::Table::Xml {
    is => 'UR::Object::Set::View::Default::Xml',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                rule_display => {
                    name => 'members',
                    perspective => 'default',
                    toolkit => 'xml',
                    subject_class_name => 'Sdm::Service::Lsof::Process',
                    aspects => [
                        'hostname',
                        'pid',
                        'command',
                        'username',
                        'uid',
                        'age',
                        'nfsd',
                        'filename',
                        #{
                        #    name => 'files',
                        #    aspects => [
                        #        'filename',
                        #    ],
                        #    perspective => 'default',
                        #    toolkit => 'xml',
                        #    subject_class_name => 'Sdm::Service::Lsof::File',
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
