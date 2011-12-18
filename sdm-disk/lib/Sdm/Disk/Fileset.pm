
package Sdm::Disk::Fileset;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Fileset {
    table_name => 'disk_fileset',
    is => 'Sdm::Disk::Volume',
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
        kb_grace        => { is => 'Text' },
        files           => { is => 'Number' },
        file_quota      => { is => 'Number' },
        file_limit      => { is => 'Number' },
        file_in_doubt   => { is => 'Number' },
        file_grace      => { is => 'Text' },
        file_entrytype  => { is => 'Text' },
        parent_volume_id => { is => 'Text' },
        volume          => {
            is => 'Sdm::Disk::Volume',
            id_by => 'parent_volume_id'
        },
        parent_volume => {
            via => 'volume', to => 'physical_path'
        },
    ],
    data_source => 'Sdm::DataSource::Disk',
};

sub create {
    my $self = shift;
    my $bx = $self->define_boolexpr(@_);

    my $kb_limit = $bx->value_for('kb_limit');
    my $kb_size  = $bx->value_for('kb_size');
    $bx = $bx->add_filter( total_kb => $kb_limit );
    $bx = $bx->add_filter( used_kb => $kb_size );

    unless ($bx->value_for('parent_volume_id')) {
        $self->error_message("missing required attribute parent_volume_id");
        return;
    }

    my $parent = Sdm::Disk::Volume->get( id => $bx->value_for('parent_volume_id'));
    unless ($parent) {
        $self->error_message("no volume identified by parent_volume_id " . $bx->value_for('parent_volume_id'));
        return;
    }
    $bx = $bx->add_filter( filername => $parent->filername );

    return $self->SUPER::create( $bx );
}

1;
