
package SDM::Gpfs::Command::MountQuery;

use strict;
use warnings;

use SDM;
use Genome;

class SDM::Gpfs::Command::MountQuery {
    is => 'SDM::Command::Base',
    doc => 'Discover what might be using a named mount_path',
    has => [
        mount_path => { is => 'Text' }
    ],
};

sub execute {

    my $self = shift;
    $self->logger->debug("Look for builds using: " . $self->mount_path);

    my @references;
    my @builds;
    my @events;
    my $othern;

    foreach my $a ( Genome::Disk::Allocation->get( mount_path => $self->mount_path ) ) {
        my $class = $a->owner_class_name;
        $self->logger->debug("found: $class " . $a->owner_id);
        if ($class =~ /^Genome::Model::Build::\S+ReferenceSequence/) {
            push @references, $a->owner;
        } elsif ($class =~ /^Genome::Model::Build$/) {
            push @builds, $a->owner;
        } elsif ($class =~ /^Genome::Model::Event$/) {
            push @events, $a->owner;
        } elsif ($class =~ /^Genome::InstrumentData/) {
            push @references, $a->owner;
        } else {
            $othern++;
        }
    }

    if (@references) {
        for my $build (@references) {
            foreach my $running_build (Genome::Model::Build->get( 'inputs.value_id' => $build->id, status => 'Running' )) {
                printf "%s has %s which is an input for running build %s %s %s\n", $self->mount_path, $build->model_name, $running_build->id,$running_build->model_name,$running_build->run_by;
            }
        }
    }

    if (@builds) {
        for my $build (@builds) {
            printf "%s has running build %s %s %s\n", $self->mount_path, $build->id, $build->model_name, $build->run_by;
        }
    }

    if (@events) {
        foreach my $running_event (Genome::Model::Event->get( id => \@events, event_status => 'Running' )) {
            printf "%s has running event %s %s %s\n", $self->mount_path, $running_event->id, $running_event->model_name, $running_event->run_by;
        }
    }

    printf "%s has %s other owners\n", $self->mount_path, $othern;

    return 1;
}

1;
