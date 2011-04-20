package System::Disk::Array;

use strict;
use warnings;

use System;
class System::Disk::Array {
    type_name => 'disk array',
    table_name => 'disk_array',
    id_by => [
        name          => { is => 'Text', len => 255 },
    ],
    has_optional => [
        model         => { is => 'Text', len => 255 },
        arraysize     => { is => 'UnsignedInteger', default => 0 },
        type          => { is => 'Text', len => 255 },
        created       => { is => 'DATE' },
        last_modified => { is => 'DATE' },
    ],
    has_many_optional => [
        mappings      => { is => 'System::Disk::HostArrayBridge', reverse_as => 'array' },
        host          => { is => 'System::Disk::Host', via => 'mappings', to => 'host' },
        hostname      => { via => 'mappings', to => 'hostname' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

sub assign {
    my $self = shift;
    my $hostname = shift;
    unless ($hostname) {
        $self->error_message("specify a hostname to assign this array to");
        return;
    }
    my $host = System::Disk::Host->get( hostname => $hostname );
    unless ($host) {
        $self->error_message("the host named '$hostname' is unknown");
        return;
    }
    my $res = System::Disk::HostArrayBridge->get_or_create( host => $host, array => $self );
    return $res;
}

sub create {
    my $self = shift;
    my (%params) = @_;
    unless ($params{name}) {
        $self->error_message("No name given for Array");
        return;
    }
    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    return $self->SUPER::create( %params );
}

sub delete {
    my $self = shift;
    # Before we remove the Array, we must remove its connection to Hosts.
    foreach my $mapping ($self->mappings) {
        $mapping->delete() or die "Failed to remove host-array mapping: $!";
    }
    return $self->SUPER::delete();
}

1;
