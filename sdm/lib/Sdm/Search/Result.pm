
package Sdm::Search::Result;

use strict;
use warnings;

class Sdm::Search::Result {
    id_by => [
        query_string => {
            is => 'Text',
        },
        page => {
            is => 'Number',
        },
        subject_class_name => {
            is => 'Text',
        },
        subject => {
            is => 'UR::Object',
            id_class_by => 'subject_class_name',
            id_by => 'subject_id'
        }
    ],
    has => [
        query => {
            is => 'Sdm::Search::Query',
            id_by => ['query_string','page','fq']
        }
    ]
};


