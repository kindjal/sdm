package Sdm::Disk::Allocation::View::Status::Xml;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Allocation::View::Status::Xml {
    is => 'Sdm::View::Status::Xml',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                'absolute_path',
                'kilobytes_requested',
                'owner_class_name',
                'owner_id',
                { name => 'build',
                  perspective => 'default',
                  subject_class_name => 'Sdm::Model::Build',
                  toolkit => 'xml',
                  aspects => ['build_id', 'model_id', 'status', 'run_by', 'date_scheduled', 'date_completed' ],
                }
            ],
        }
    ]
};

1;

