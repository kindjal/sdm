
package Sdm::Service::Automount::Command::Export;

use strict;
use warnings;

use Sdm;
use File::Basename qw/basename/;

class Sdm::Service::Automount::Command::Export {
    is  => 'Sdm::Command::Base',
    has => [
        filename => {
            is => 'Text',
            default_value => '',
            doc => 'filename to store automount configuration',
        }
    ],
};

sub execute {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " execute");

    if ($self->filename) {
        Sdm::DataSource::Automount->_singleton_object->filename($self->filename);
        $self->logger->debug(__PACKAGE__ . " set db path to " .  Sdm::DataSource::Automount->_singleton_object->filename);
    }

    my $data;
    foreach my $volume ( Sdm::Disk::Volume->get() ) {

        my $name = basename $volume->physical_path;
        my $item = Sdm::Service::Automount->get_or_create(
            name => $name,
            mount_options => $volume->mount_options,
            filername => $volume->filername,
            physical_path => $volume->physical_path
        );
    }
    return 1;
}

sub help_brief {
    return 'dump automount configuration';
}

1;
