
package System::Search::Result;

use strict;
use warnings;

class System::Search::Result {
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
            is => 'System::Search::Query',
            id_by => ['query_string','page','fq']
        }
    ]
};


