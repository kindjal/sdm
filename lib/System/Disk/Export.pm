package System::Disk::Export;

use strict;
use warnings;

use System;

class System::Disk::Export {
    table_name => 'DISK_EXPORT',
    id_by => [
        id              => { is => 'Number' },
    ],
    has => [
        filername       => { is => 'Text', len => 255 },
        physical_path   => { is => 'Text', len => 255 },
        filer           => { is => 'System::Disk::Filer', id_by => 'filername' },
    ],
    has_optional => [
        volume          => { is => 'System::Disk::Volume', id_by => 'id' },
        created         => { is => 'DATE' },
        last_modified   => { is => 'DATE' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

sub create {
    my ($self,%params) = @_;
    my $export = System::Disk::Export->get( filername => $params{filername}, physical_path => $params{physical_path} );
    if (defined $export) {
        $self->warning_message("Export already exists: " . $params{filername} . " " . $params{physical_path} );
        return;
    }
    my $filer = System::Disk::Filer->get_or_create( name => $params{filername} );
    if (! defined $filer) {
        $self->warning_message("Filer '" . $params{filername} . "' does not exist and adding it failed.");
        return;
    }
    return $self->SUPER::create( %params );
}

1;
