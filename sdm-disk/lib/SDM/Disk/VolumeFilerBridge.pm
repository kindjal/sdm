
package SDM::Disk::VolumeFilerBridge;

class SDM::Disk::VolumeFilerBridge {
    table_name => 'disk_volume_filer',
    id_by => [
        filername => { is => 'Text' },
        volume_id => { is => 'Text' },
    ],
    has => [
        filer       => { is => 'SDM::Disk::Filer', id_by => 'filername' },
        volume      => { is => 'SDM::Disk::Volume', id_by => 'volume_id' },
    ],
    schema_name => 'Disk',
    data_source => 'SDM::DataSource::Disk',
};

1;
