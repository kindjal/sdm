
package Sdm::Disk::Array;

use strict;
use warnings;

use Sdm;
class Sdm::Disk::Array {
    type_name => 'disk array',
    table_name => 'disk_array',
    id_by => [
        name          => { is => 'Text', len => 255 },
    ],
    has_many => [
        disk_sets     => { is => 'Sdm::Disk::ArrayDiskSet', reverse_as => 'array' },
        disk_type     => { is => 'Text', via => 'disk_sets' },
    ],
    has_optional => [
        manufacturer  => { is => 'Text' },
        model         => { is => 'Text' },
        serial        => { is => 'Text' },
        comments      => { is => 'Text' },
        disk_set_num  => {
            is => 'Integer',
            calculate => q| my @s = $self->disk_sets; return scalar @s;|,
        },
        arraysize     => {
            is => 'Sdm::Value::KBytes',
            calculate => q| my $s = 0; for $b ($self->disk_sets) { my $c = $b->capacity; $s+=$c if ($c); }; return Sdm::Value::KBytes->get($s); |,
        },
        created       => { is => 'DATE' },
        last_modified => { is => 'DATE' },
    ],
    has_many_optional => [
        mappings      => { is => 'Sdm::Disk::HostArrayBridge', reverse_as => 'array' },
        host          => { is => 'Sdm::Disk::Host', via => 'mappings', to => 'host' },
        hostname      => { is => 'Text', via => 'host', to => 'hostname' },
    ],
    has_constant => [
        default_aspects => {
            column_name => '',
            is_classwide => 1,
            is => 'HASH',
            value => {
                visible  => [ 'name','manufacturer','model','serial','arraysize','created','last_modified','hostname' ],
                editable => [ 'name','manufacturer','model','serial' ],
            }
        }
    ],
    schema_name => 'Disk',
    data_source => 'Sdm::DataSource::Disk',
};

sub assign {
    my $self = shift;
    my $hostname = shift;
    unless ($hostname) {
        $self->error_message("specify a hostname to assign this array to");
        return;
    }
    my $host = Sdm::Disk::Host->get( hostname => $hostname );
    unless ($host) {
        $self->error_message("the host named '$hostname' is unknown");
        return;
    }
    my $res = Sdm::Disk::HostArrayBridge->get_or_create( host => $host, array => $self );
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

=head2 update
Update Arrays
=cut
sub update {
    my $self = shift;
    my (%params) = @_;
    if ($params{name} and $self->name ne $params{name}) {
        $self->logger->error(__PACKAGE__ . " name mismatch: " . $self->name . " vs. " . $params{name});
        return;
    }
    foreach my $key (keys %params) {
        $self->$key( $params{$key} );
    }
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
