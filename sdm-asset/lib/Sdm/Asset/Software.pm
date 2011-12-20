
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
    ],
    has_constant => [
        default_aspects => {
            column_name => '',
            doc => 'This is used by the web UI to draw a jquery-datatables view of a set of objects. Here we specify which attributes are visible and their order, and which attributes should be editable.',
            is_classwide => 1,
            is => 'HASH',
            value => {
                'visible'  => ['manufacturer','product','license','description','seats','comments','created','last_modified'],
                'editable' => ['manufacturer','product','license','seats','description','comments'],
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
