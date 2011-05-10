
package System::Disk::GpfsNode;

use strict;
use warnings;

use System;

class System::Disk::GpfsNode{
    table_name => 'disk_gpfs_node',
    id_by => [
        gpfsNodeName => { is => 'Text' }
    ],
    has => [
        gpfsNodeIP            => { is => 'Text', default_value => '' },
        gpfsNodePlatform      => { is => 'Text', default_value => '' },
        gpfsNodeStatus        => { is => 'Text', default_value => '' },
        gpfsNodeFailureCount  => { is => 'Text', default_value => '' },
        gpfsNodeThreadWait    => { is => 'Text', default_value => '' },
        gpfsNodeHealthy       => { is => 'Text', default_value => '' },
        gpfsNodeDiagnosis     => { is => 'Text', default_value => '' },
        gpfsNodeVersion       => { is => 'Text', default_value => '' },
    ],
    has_optional => [
        created         => { is => 'Date' },
        last_modified   => { is => 'Date' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

=head2 create
Create method for gpfsNodeTable entry sets created attribute.
=cut
sub create {
    my $self = shift;
    my (%params) = @_;
    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    my $hostname = $params{gpfsNodeName};
    unless ($hostname) {
        $self->error_message("parameters missing required attribute: gpfsNodeName");
        return;
    }
    my $host = System::Disk::Host->get( hostname => $hostname );
    unless ($host) {
        $self->error_message("can't find a host with hostname '$hostname'" );
        return;
    }
    return $self->SUPER::create( %params );
}

1;
