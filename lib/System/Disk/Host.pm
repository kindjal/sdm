package System::Disk::Host;

use strict;
use warnings;

use System;
class System::Disk::Host {
    table_name => 'DISK_HOST',
    id_by => [
        hostname      => { is => 'Text', len => 255 },
    ],
    has => [
        filer         => { is => 'System::Disk::Filer', id_by => 'filername', constraint_name => 'HOST_FILER_FK' },
    ],
    has_optional => [
        comments      => { is => 'Text', len => 255 },
        created       => { is => 'DATE' },
        last_modified => { is => 'DATE' },
        location      => { is => 'Text', len => 255 },
        os            => { is => 'Text', len => 255 },
        status        => { is => 'UnsignedInteger' },
    ],
    has_many_optional => [
        arrays => { is => 'System::Disk::Array', reverse_as => 'host' },
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
