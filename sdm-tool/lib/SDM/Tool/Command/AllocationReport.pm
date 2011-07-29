
package SDM::Tool::Command::AllocationReport;

use strict;
use warnings;

class SDM::Tool::Command::AllocationReport {
    is => 'SDM::Command::Base',
    has_optional => [
        build_id => {
            is => 'Number'
        },
        job_id => {
            is => 'Number'
        }
    ]
};

use SDM;
use Genome;
use Data::Dumper;

sub execute {

    my $self = shift;

    # By default, look for all builds corresponding to running jobs.
    my @jobs;
    my @build_ids;

    if ($self->build_id and $self->job_id) {
        $self->logger->error(__PACKAGE__ . " build_id and job_id are mutually exclusive");
        return;
    } elsif ($self->build_id) {
        push @build_ids, $self->build_id;
    } elsif ($self->job_id) {
        push @jobs, $self->job_id
    } else {
        @jobs = SDM::Rtm::Jobs->get( stat => "RUNNING" );
        unless (@jobs) {
            $self->logger->error(__PACKAGE__ . " no running jobs found");
            return;
        }
    }

    if (@jobs) {
        $self->logger->info(__PACKAGE__ . " " . scalar @jobs + 1 . " running jobs");
        foreach my $job (@jobs) {
            my $name = $job->projectName;
            if ($name =~ /^build(\d+)/ ) {
                push @build_ids, $1;
            }
        }
    }

    unless (@build_ids) {
        $self->logger->error(__PACKAGE__ . " no running builds found");
        return;
    }

    my $allocations;
    my @builds = Genome::Model::Build->get( id => \@build_ids );

    foreach my $build (@builds) {
        print "build " . $build->id ."\n";
        print "  data_directory " . $build->data_directory . "\n";

        foreach my $allocation ($build->all_allocations) {
            next if ($build->data_directory eq $allocation->absolute_path);
            print "  input_path " . $allocation->absolute_path . "\n";
        }

        my @sru = Genome::SoftwareResult::User->get( user_id => $build->id, user_class_name => $build->subclass_name );
        foreach my $sru (@sru) {
            my $sr = $sru->software_result;
            print "  software_result " . $sr->output_dir . "\n";
        }
        print "\n";
    }
    return 1;
}

1;

