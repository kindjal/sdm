
package Sdm::Tool::Command::AllocationReport;

use strict;
use warnings;

class Sdm::Tool::Command::AllocationReport {
    is => 'Sdm::Command::Base',
    doc => 'find disk allocations used by running builds/jobs',
    has_optional => [
        build_id => {
            is => 'Number',
            doc => 'show me all allocations for this build id',
        },
        job_id => {
            is => 'Number',
            doc => 'show me all allocations for this job id, assuming the job is part of a Model Build'
        },
        volume => {
            is => 'Text',
            doc => 'filter allocations for this named volume'
        }
    ]
};

use Sdm;
use Genome;
use Data::Dumper;

sub help_detail {
    return <<EOF;
Query for disk allocations used by running builds.  Some examples:

Show me all allocations used by running builds:
  sdm tool allocation-report | tee output.txt

Show me all allocations used by build 1234
  sdm tool allocation-report --build-id 1234 | tee output.txt

Show me all allocations used by job 1234, assuming job 1234 is a Build:
  sdm tool allocation-report --job-id 1234 | tee output.txt

Show me all builds using volume gc2111:
  sdm tool allocation-report --volume gc2111 | tee output.txt

EOF
}

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
        @jobs = Sdm::Rtm::Jobs->get( jobid => $self->job_id  );
    } else {
        $self->logger->warn(__PACKAGE__ . " finding all running jobs");
        @jobs = Sdm::Rtm::Jobs->get( stat => "RUNNING" );
        unless (@jobs) {
            $self->logger->error(__PACKAGE__ . " no running jobs found");
            return;
        }
    }

    if (@jobs) {
        $self->logger->warn(__PACKAGE__ . " " . scalar @jobs . " running jobs");
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

    $self->logger->debug(__PACKAGE__ . " query for builds");
    my @builds = Genome::Model::Build->get( id => \@build_ids );

    $self->logger->warn(__PACKAGE__ . " finding allocations for " . scalar @builds . " running builds");
    my $allocations;

    my @header = ('Build ID','Build Subclass','Model Name','Processing Profile','Allocation Type','Path');
    print join(",",@header) . "\n";
    foreach my $build (@builds) {
        $self->logger->debug(__PACKAGE__ . " examine build " . $build->id);
        my $paths;

        $paths->{data_directory} = [];
        push @{ $paths->{data_directory} }, $build->data_directory;

        foreach my $allocation ($build->all_allocations) {
            next if ($build->data_directory eq $allocation->absolute_path);
            $paths->{input_path} = [];
            push @{ $paths->{input_path} }, $allocation->absolute_path;
        }

        $self->logger->debug(__PACKAGE__ . " " . $build->id . " " . $build->subclass_name);
        my @sru = Genome::SoftwareResult::User->get( user_id => $build->id, user_class_name => $build->subclass_name );
        foreach my $sru (@sru) {
            my $sr = $sru->software_result;
            $paths->{software_result} = [];
            push @{ $paths->{software_result} }, $sr->output_dir;
        }

        if ($self->volume) {
            # Filter results for named volume
            my @paths = values %$paths;
            while (my ($k,$v) = each %$paths) {
                my @list;
                foreach my $path (@$v) {
                    my $vol = $self->volume;
                    push @list, $path if ($path =~ /$vol/);
                }
                if (@list) {
                    $paths->{$k} = \@list;
                } else {
                    delete $paths->{$k};
                }
            }
            next unless (keys %$paths);
        }

        my @row = ($build->id,$build->subclass_name,$build->model_name,$build->processing_profile_name);
        while (my ($k,$v) = each %$paths) {
            #my @lines = map { "\t$k $_" } @{ $paths->{$k}};
            #push @row,@lines;
            @row = (@row,$k,@{ $paths->{$k} });
        }
        print join(",",@row) . "\n";
    }

    return 1;
}

1;

