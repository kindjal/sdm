package SDM::Disk::Group;

use strict;
use warnings;

use SDM;

class SDM::Disk::Group {
    table_name => 'disk_group',
    id_by => [
        name => { is => 'Text' },
    ],
    has => [
        permissions     => { is => 'UnsignedInteger', default => 0 },
        sticky          => { is => 'UnsignedInteger', default => 0 },
        unix_gid        => { is => 'UnsignedInteger', default => 0 },
        unix_uid        => { is => 'UnsignedInteger', default => 0 },
        subdirectory    => { is => 'Text', default => 'info' },
    ],
    has_optional => [
        created         => { is => 'DATE' },
        last_modified   => { is => 'DATE' },
    ],
    schema_name => 'Disk',
    data_source => 'SDM::DataSource::Disk',
    doc => 'Represents a disk group which contains any number of disk volumes',
};

sub get_or_create {
    my $self = shift;
    return $self->get( @_ ) || $self->create( @_ );
}

sub create {
    my $self = shift;
    my (%params) = @_;
    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    return $self->SUPER::create( %params );
}

1;
