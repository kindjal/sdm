
package SDM::Disk::FilerHostBridge;

class SDM::Disk::FilerHostBridge {
    table_name => 'disk_filer_host',
    id_by => [
        filername => { is => 'Text' },
        hostname  => { is => 'Text' },
    ],
    has => [
        filer       => { is => 'SDM::Disk::Filer', id_by => 'filername' },
        host        => { is => 'SDM::Disk::Host', id_by => 'hostname' },
    ],
    schema_name => 'Disk',
    data_source => 'SDM::DataSource::Disk',
};

1;
