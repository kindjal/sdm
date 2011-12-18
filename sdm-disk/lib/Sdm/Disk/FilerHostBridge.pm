
package Sdm::Disk::FilerHostBridge;

class Sdm::Disk::FilerHostBridge {
    table_name => 'disk_filer_host',
    id_by => [
        filername => { is => 'Text' },
        hostname  => { is => 'Text' },
    ],
    has => [
        filer       => { is => 'Sdm::Disk::Filer', id_by => 'filername' },
        host        => { is => 'Sdm::Disk::Host', id_by => 'hostname' },
    ],
    schema_name => 'Disk',
    data_source => 'Sdm::DataSource::Disk',
};

1;
