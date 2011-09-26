
package SDM::Disk::Fileset;

use strict;
use warnings;

use SDM;

class SDM::Disk::Fileset {
    table_name => 'disk_fileset',
    is => 'SDM::Disk::Volume',
    has => [
        type            => { is => 'Text', default_value => 'FILESET' },
        kb_quota        => { is => 'Number' },
        kb_limit        => { is => 'Number' },
        kb_in_doubt     => { is => 'Number' },
        kb_grace        => { is => 'Number' },
        files           => { is => 'Number' },
        file_quota      => { is => 'Number' },
        file_limit      => { is => 'Number' },
        file_in_doubt   => { is => 'Number' },
        file_grace      => { is => 'Number' },
        file_entryType  => { is => 'Text' },
        parent_volume_name => { is => 'Text' },
        volume          => {
            is => 'SDM::Disk::Volume',
            id_by => 'parent_volume_name'
        },
        mount_path      => {
            is => 'Text',
            is_calculated => 1,
            calculate_from => [ 'name','mount_point', 'parent_volume_name' ],
            calculate => q| return $mount_point . "/" . "$parent_volume_name" . "/" . $name |,
        }
    ],
    data_source => 'SDM::DataSource::Disk',
};

sub create {
    my $self = shift;
    my (%param) = @_;

    unless ($param{ parent_volume_name }) {
        $self->error_message("missing required attribute parent_volume_name");
        return;
    }

    my $parent = SDM::Disk::Volume->get( name => $param{ parent_volume_name } );
    unless ($parent) {
        $self->error_message("no volume identified by parent_volume_name " . $param{ parent_volume_name });
        return;
    }

    return $self->SUPER::create( %param );
}

1;
