package System::Disk::Array;

use strict;
use warnings;

use System;
class System::Disk::Array {
    type_name => 'disk array',
    table_name => 'DISK_ARRAY',
    id_by => [
        name          => { is => 'Text', len => 255 },
    ],
    has => [
        host          => { is => 'System::Disk::Host', id_by => 'hostname', constraint_name => 'ARRAY_HOST_FK' },
    ],
    has_optional => [
        model         => { is => 'Text', len => 255 },
        size          => { is => 'UnsignedInteger' },
        type          => { is => 'Text', len => 255 },
        created       => { is => 'DATE' },
        last_modified => { is => 'DATE' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

sub create {
    my $self = shift;
    my %params = @_;
    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    return $self->SUPER::create( %params );
}

1;
