package Sdm::Service::Base;

use strict;
use warnings;
use Sdm;

class Sdm::Service::Base {
    is => ['Command::V2'],
    has_optional => [
         version => {
             is    => 'String',
             doc   => 'version of application to use',
         },
    ],
    attributes_have => [
        file_format => {
            is => 'Text',
            is_optional => 1,
        }
    ],
    doc => "web app"
};

sub help_detail { "" }

1;
