
package System::Disk::FilerHostBridge;

class System::Disk::FilerHostBridge {
    table_name => 'DISK_FILER_HOST',
    id_by => [
        filername => { is => 'Text' },
        hostname  => { is => 'Text' },
    ],
    has => [
        filer       => { is => 'System::Disk::Filer', id_by => 'filername' },
        host        => { is => 'System::Disk::Host', id_by => 'hostname' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

