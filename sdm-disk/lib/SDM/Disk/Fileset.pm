
package SDM::Disk::Fileset;

use strict;
use warnings;

use SDM;

class SDM::Disk::Fileset {
    table_name => 'disk_fileset',
    is => 'SDM::Disk::Volume',
    id_generator => '-uuid',
    id_by => [
        id              => { is => 'Text' },
    ],
    has => [
        type            => { is => 'Text', default_value => 'FILESET' },
        kb_size         => { is => 'Number' },
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
        parent_volume_id => { is => 'Text' },
        volume          => {
            is => 'SDM::Disk::Volume',
            id_by => 'parent_volume_id'
        },
        parent_volume => {
            via => 'volume', to => 'physical_path'
        },
    ],
    data_source => 'SDM::DataSource::Disk',
};

sub create {
    my $self = shift;
    my (%param) = @_;

    unless ($param{ parent_volume_id }) {
        $self->error_message("missing required attribute parent_volume_id");
        return;
    }

    my $parent = SDM::Disk::Volume->get( id => $param{parent_volume_id} );
    unless ($parent) {
        $self->error_message("no volume identified by parent_volume_id " . $param{ parent_volume_id});
        return;
    }

    # Set Volume attrs
    $param{ total_kb } = $param{ kb_limit };
    $param{ used_kb  } = $param{ kb_size };

    return $self->SUPER::create( %param );
}

1;
