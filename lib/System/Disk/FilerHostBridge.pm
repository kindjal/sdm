
package System::Disk::FilerHostBridge;

class System::Disk::FilerHostBridge {
    table_name => 'DISK_FILER_HOST',
    id_by => [
        filername => { is => 'Text' },
        hostname  => { is => 'Text' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

