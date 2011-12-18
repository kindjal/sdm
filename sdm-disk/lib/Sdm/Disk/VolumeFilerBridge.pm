
package Sdm::Disk::VolumeFilerBridge;

class Sdm::Disk::VolumeFilerBridge {
    table_name => 'disk_volume_filer',
    id_by => [
        filername => { is => 'Text' },
        volume_id => { is => 'Text' },
    ],
    has => [
        filer       => { is => 'Sdm::Disk::Filer', id_by => 'filername' },
        volume      => { is => 'Sdm::Disk::Volume', id_by => 'volume_id' },
    ],
    schema_name => 'Disk',
    data_source => 'Sdm::DataSource::Disk',
};

1;
