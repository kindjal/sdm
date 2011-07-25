
package SDM::Service::Automount::Command::Export;

use strict;
use warnings;

use SDM;

class SDM::Service::Automount::Command::Export {
    is  => 'SDM::Command::Base',
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
        #SDM::DataSource::Automount->filename($self->filename);
        SDM::DataSource::Automount->_singleton_object->filename($self->filename);
        $self->logger->debug(__PACKAGE__ . " set db path to " .  SDM::DataSource::Automount->_singleton_object->filename);
    }

    my $data;
    foreach my $volume ( SDM::Disk::Volume->get() ) {

        my $item = SDM::Service::Automount->get_or_create(
            name => $volume->name,
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
