
package SDM::Disk::GpfsNode;

use strict;
use warnings;

use SDM;

class SDM::Disk::GpfsNode{
    table_name => 'disk_gpfs_node',
    id_by => [
        gpfsNodeName => { is => 'Text', column_name => 'gpfsnodename' }
    ],
    has => [
        gpfsNodeIP            => { is => 'Text', default_value => '', column_name => 'gpfsnodeip' },
        gpfsNodePlatform      => { is => 'Text', default_value => '', column_name => 'gpfsnodeplatform' },
        gpfsNodeStatus        => { is => 'Text', default_value => '', column_name => 'gpfsnodestatus' },
        gpfsNodeFailureCount  => { is => 'Text', default_value => '', column_name => 'gpfsnodefailurecount' },
        gpfsNodeThreadWait    => { is => 'Text', default_value => '', column_name => 'gpfsnodethreadwait' },
        gpfsNodeHealthy       => { is => 'Text', default_value => '', column_name => 'gpfsnodehealthy' },
        gpfsNodeDiagnosis     => { is => 'Text', default_value => '', column_name => 'gpfsnodediagnosis' },
        gpfsNodeVersion       => { is => 'Text', default_value => '', column_name => 'gpfsnodeversion' },
    ],
    has_optional => [
        created         => { is => 'Date' },
        last_modified   => { is => 'Date' },
    ],
    schema_name => 'Disk',
    data_source => 'SDM::DataSource::Disk',
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
    my $host = SDM::Disk::Host->get( hostname => $hostname );
    unless ($host) {
        $self->error_message("can't find a host with hostname '$hostname'" );
        return;
    }
    return $self->SUPER::create( %params );
}

1;
