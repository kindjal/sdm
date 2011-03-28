
package System::Disk::HostArrayBridge;

class System::Disk::HostArrayBridge {
    table_name => 'DISK_HOST_ARRAY',
    id_by => [
        hostname  => { is => 'Text' },
        arrayname => { is => 'Text' },
    ],
    has => [
        host        => { is => 'System::Disk::Host', id_by => 'hostname' },
        array       => { is => 'System::Disk::Array', id_by => 'arrayname' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

sub get_or_create {
    my $self = shift;
    my (%params) = @_;
    my $res = System::Disk::HostArrayBridge->get( host => $params{host}, array => $params{array} );
    unless ($res) {
        $res = $self->create( host => $params{host}, array => $params{array} );
    }
    return $res;
}

sub create {
    my $self = shift;
    my (%params) = @_;
    my $res = System::Disk::HostArrayBridge->get( host => $params{host}, array => $params{array} );
    if ($res) {
        $self->error_message("Array '" . $params{array}->name . "' is already assigned to Host '" . $params{host}->hostname . "'");
        return;
    }
    return $self->SUPER::create( host => $params{host}, array => $params{array} );
}
