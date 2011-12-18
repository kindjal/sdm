
package Sdm::Service::Lsof::Process;

use strict;
use warnings;
use feature "switch";

use Sdm;
use Date::Manip;

class Sdm::Service::Lsof::Process {
    is => 'Sdm::Service::Lsof',
    data_source => 'Sdm::DataSource::Service',
    schema_name => 'Service',
    table_name => 'service_lsof_process',
    id_by => [
        hostname      => { is => 'Text' },
        pid           => { is => 'Integer' }
    ],
    has => [
        pgid          => { is => 'Integer' },
        uid           => { is => 'Integer', default => 0 },
        username      => { is => 'Text', default => '' },
        command       => { is => 'Text', default => '' },
        # Allows us to identify child processes, see family
        pg_leader     => { is => 'Sdm::Service::Lsof::Process', id_by => ['hostname','pgid'] },
    ],
    has_many_optional => [
        files         => { is => 'Sdm::Service::Lsof::File', reverse_as => 'process' },
        filename      => { is => 'Text', via => 'files' },
        # 'pg' is process group and had been called 'children'
        # But this includes the process group leader in the result, which is suboptimal, but fine for now.
        pg            => {
            is        => 'Sdm::Service::Lsof::Process',
            reverse_as => 'pg_leader',
            doc       => 'All processes in the process group',
        },
    ],
    has_optional => [
        job            => {
            is        => 'Sdm::Rtm::Jobs',
            is_calculated => 1,
            reverse_as => 'process',
            calculate_from => [ 'hostname','pgid' ],
            calculate => q| Sdm::Rtm::Jobs->get( exec_host => $hostname, jobPid => $pgid ); |,
        },
        nfsd          => { is => 'Text' },
        created       => { is => 'Date' },
        last_modified => { is => 'Date' },
        age           => {
            is_calculated => 1,
            calculate => q| return $self->age |,
        },
    ],
};

sub age {
    my $self = shift;

    my $err;
    my $created = $self->created;
    my $last_modified = $self->last_modified;
    return 0 unless ($created and $last_modified);
    $created =~ s/[- ]/:/g;
    $last_modified =~ s/[- ]/:/g;
    my $date0 = ParseDate($created);
    my $date1 = ParseDate($last_modified);
    my $calc  = DateCalc($date0,$date1,\$err);
    my $delta = Delta_Format($calc,0,'%st');
    return $delta;
}

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
                    my $result = Sdm::Service::Lsof::File->get_or_create( hostname => $self->hostname, pid => $self->pid, filename => $file );
                    unless ($result) {
                        $self->error_message("failed to create file object $file for " . $self->pid);
                    }
                }
                # Remove stored files that aren't currently open
                foreach my $file ( Sdm::Service::Lsof::File->get( hostname => $self->hostname, pid => $self->pid) ) {
                    my $name = $file->filename;
                    unless ( not grep { /^$name$/ } @{ $record->{'name'} } ) {
                        $file->delete;
                    }
                }
            }
            default {
                my $p = $self->__meta__->property($attr);
                $self->$attr( $record->{$attr} ) if (! $p->is_id and $p->is_mutable);
            }
        }
    }
    $self->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
}

=head2 create
Create a new Lsof::Process record.
=cut
sub create {
    my $self = shift;
    my ($params) = @_;
    my $hostname = $params->{hostname};
    my $pid = $params->{pid};
    unless ($params->{pgid}) {
        $params->{pgid} = $pid;
    }

    my $files = delete $params->{name};
    if ($files) {
        my @files;
        if (ref $files eq 'ARRAY') {
            @files = grep { defined $_ } @$files;
        } else {
            @files = [ $files ];
        }
        foreach my $file (@files) {
            my $result = Sdm::Service::Lsof::File->get_or_create( hostname => $hostname, pid => $pid, filename => $file );
            unless ($result) {
                $self->error_message("failed to create file object $file for $pid");
            }
        }
    }

    $params->{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    return $self->SUPER::create( $params );
}

1;
