
package SDM::Service::Lsof::Process;

use strict;
use warnings;

use SDM;

class SDM::Service::Lsof::Process {
    is => 'SDM::Service::Lsof',
    data_source => 'SDM::DataSource::Service',
    schema_name => 'Service',
    table_name => 'service_lsof_process',
    id_by => [
        hostname      => { is => 'Text' },
        pid           => { is => 'Integer' }
    ],
    has => [
        uid           => { is => 'Integer', default => 0 },
        time          => { is => 'Integer', default => 0 },
        timedelta     => { is => 'Integer', default => 0 },
        user          => { is => 'Text', default => '' },
        command       => { is => 'Text', default => '' },
    ],
    has_many_optional => [
        files         => { is => 'SDM::Process::Lsof::File', reverse_as => 'process' },
    ],
    has_optional => [
        created       => { is => 'Date' },
        last_modified => { is => 'Date' }
    ],
};

sub create {
    my $self = shift;
    my ($params) = @_;
    my $hostname = $params->{hostname};
    my $pid = $params->{pid};

    my $files = delete $params->{name};
    if ($files) {
        my @files;
        if (ref $files eq 'ARRAY') {
            @files = grep { defined $_ } @$files;
        } else {
            @files = [ $files ];
        }
        foreach my $file (@files) {
            my $result = SDM::Service::Lsof::File->get_or_create( hostname => $hostname, pid => $pid, filename => $file );
            unless ($result) {
                $self->error_message("failed to create file object $file for $pid");
            }
        }
    }

    return $self->SUPER::create( $params );
}

1;
