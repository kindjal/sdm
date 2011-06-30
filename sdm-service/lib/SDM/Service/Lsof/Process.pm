
package SDM::Service::Lsof::Process;

use strict;
use warnings;
use feature "switch";

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
        files         => { is => 'SDM::Service::Lsof::File', reverse_as => 'process' },
        filename      => { is => 'Text', via => 'files' },
    ],
    has_optional => [
        created       => { is => 'Date' },
        last_modified => { is => 'Date' }
    ],
};

=head2 create
Update a Process record... this is primarily to handle the filenames part.
=cut
sub update {
    my $self = shift;
    my $record = shift;
    foreach my $attr (keys %$record) {
        given ($attr) {
            when (/^name$/) {
                # Ensure all new files are stored
                foreach my $file (@{ $record->{'name'} }) {
                    my $result = SDM::Service::Lsof::File->get_or_create( hostname => $self->hostname, pid => $self->pid, filename => $file );
                    unless ($result) {
                        $self->error_message("failed to create file object $file for " . $self->pid);
                    }
                }
                # Remove stored files that aren't currently open
                foreach my $file ( SDM::Service::Lsof::File->get( hostname => $self->hostname, pid => $self->pid) ) {
                    my $name = $file->filename;
                    unless ( not grep { /^$name$/ } @{ $record->{'name'} } ) {
                        $file->delete;
                    }
                }
            }
            when (/^timedelta$/) {
                $self->timedelta( $record->{timedelta} );
            }
            when (/^last_modified$/) {
                $self->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
            }
            default {
                my $p = $self->__meta__->property($attr);
                $self->$attr( $record->{$attr} ) if (! $p->is_id and $p->is_mutable);
            }
        }
    }
}

=head2 create
Create a new Lsof::Process record.
=cut
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
