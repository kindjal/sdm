package Sdm::Disk::User;

use strict;
use warnings;

use Sdm;
class Sdm::Disk::User {
    table_name => 'disk_user',
    id_by => [
        email => { is => 'Text', len => 255 },
    ],
    has_optional => [
        created       => { is => 'DATE' },
        last_modified => { is => 'DATE' },
    ],
    schema_name => 'Disk',
    data_source => 'Sdm::DataSource::Disk',
};

sub create {
    my $self = shift;
    my %params = @_;
    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    return $self->SUPER::create( %params );
}

1;
