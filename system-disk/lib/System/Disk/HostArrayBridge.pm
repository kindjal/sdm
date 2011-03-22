
package System::Disk::HostArrayBridge;

class System::Disk::HostArrayBridge {
    table_name => 'DISK_HOST_ARRAY',
    id_by => [
        hostname  => { is => 'Text' },
        arrayname => { is => 'Text' },
    ],
    has => [
        host        => { is => 'System::Disk::Host', id_by => 'hostname' },
        array       => { is => 'System::Disk::Array', id_by => 'arrayname' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

