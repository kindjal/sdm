
package System::Disk::Mount;

class System::Disk::Mount {
    table_name => 'disk_mount',
    id_by => [
        export_id => { is => 'Number' },
        volume_id => { is => 'Number' },
    ],
    has => [
        volume        => { is => 'System::Disk::Volume', id_by => 'volume_id' },
        mount_path    => { via => 'volume' },
        export        => { is => 'System::Disk::Export', id_by => 'export_id' },
        physical_path => { via => 'export' },
        filer         => { is => 'System::Disk::Filer', via => 'export', to => 'filer' },
        filername     => { via => 'filer', to => 'name' },
        hostname      => { via => 'filer', to => 'hostname' },
        arrayname     => {
            calculate => q/ my %h; foreach my $f ($self->filer) { map { $h{$_} = 1 } $f->arrayname }; return keys %h; /
        },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

1;
