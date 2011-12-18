
package Sdm::Asset::Software;

use Sdm;

class Sdm::Asset::Software {
    schema_name => 'Asset',
    data_source => 'Sdm::DataSource::Asset',
    table_name => 'asset_software',
    id_generator => '-uuid',
    id_by => {
        id => {
            is => 'Text',
            doc => 'The generated UUID id for software',
        }
    },
    has_optional => [
        manufacturer  => { is => 'Text' },
        product       => { is => 'Text' },
        license       => { is => 'Text' },
        seats         => { is => 'Number' },
        description   => { is => 'Text' },
        comments      => { is => 'Text' },
        created       => { is => 'Date' },
        last_modified => { is => 'Date' },
    ]
};

sub create {
    my $self = shift;
    my (%params) = @_;
    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    return $self->SUPER::create( %params );
}

1;
