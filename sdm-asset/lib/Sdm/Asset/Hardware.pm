
package Sdm::Asset::Hardware;

use Sdm;

class Sdm::Asset::Hardware {
    schema_name => 'Asset',
    data_source => 'Sdm::DataSource::Asset',
    table_name => 'asset_hardware',
    id_generator => '-uuid',
    id_by => {
        id => {
            is => 'Text',
            doc => 'The generated UUID id for hardware'
        }
    },
    has => [
        hostname      => { is => 'Text' },
    ],
    has_optional => [
        tag           => { is => 'Text' },
        manufacturer  => { is => 'Text' },
        model         => { is => 'Text' },
        serial        => { is => 'Text' },
        description   => { is => 'Text' },
        comments      => { is => 'Text' },
        location      => { is => 'Text' },
        warranty_expires => { is => 'Date' },
        created       => { is => 'Date' },
        last_modified => { is => 'Date' },
    ],
    has_constant => [
        default_aspects => {
            column_name => '',
            is => 'HASH',
            is_classwide => 1,
            value => {
                visible  => ['hostname','tag','manufacturer','model','serial','description','comments','location','warranty_expires','created','last_modified'],
                editable => ['hostname','tag','manufacturer','model','serial','description','comments','location','warranty_expires']
            }
        }
    ]
};

sub create {
    my $self = shift;
    my (%params) = @_;
    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    return $self->SUPER::create( %params );
}

1;
