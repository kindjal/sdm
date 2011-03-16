
package System::Disk::Mount;

class System::Disk::Mount {
    table_name => 'DISK_MOUNT',
    id_by => [
        export_id => { is => 'Number' },
        volume_id => { is => 'Number' },
    ],
    has => [
        volume        => { is => 'System::Disk::Volume', id_by => 'volume_id' },
        mount_path    => { via => 'volume' },
        export        => { is => 'System::Disk::Export', id_by => 'export_id' },
        filername     => { via => 'export' },
        physical_path => { via => 'export' }
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};
