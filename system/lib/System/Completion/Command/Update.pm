package System::Completion::Command::Update;

use strict;
use warnings;

class System::Completion::Command::Update {
    is => 'System::Command::Base',
    doc => 'update the tab completion spec files (.opts)',
    has => [
        git_add => {
            is => 'Boolean',
            doc => 'git add the changed files after update',
            default => 0,
        },
        git_commit => {
            is => 'Boolean',
            doc => 'git commit the changed files after update',
            default => 0,
        },
    ],
};

sub help_detail {
    my $help_detail;

    $help_detail .= "Updates the tab completion spec files:\n";
    $help_detail .= " * System/Command.pm.opts\n";
    $help_detail .= " * System/Model/Tools.pm.opts";

    return $help_detail;
}

sub execute {
    my $self = shift;

    my @command_classes = ('System::Model::Tools', 'Genome::Command');
    for my $classname (@command_classes) {
        my $genome_completion = UR::Namespace::Command::Update::TabCompletionSpec->create(
            classname => $classname,
        );
        unless ($genome_completion->execute) {
            $self->error_message("Updating the $classname spec file did not complete succesfully!");
        }
    }

    $self->status_message("Committing any updated .opts file(s)!");
    my @files = `git status -s`;
    map { chomp $_ } @files;
    my ($gmt_opts) = grep { $_ =~ /Tools\.pm\.opts/ } @files;
    $gmt_opts =~ s/^\s*M\s*//;
    my ($genome_opts) = grep { $_ =~ /Command\.pm\.opts/ } @files;
    $genome_opts =~ s/^\s*M\s*//;
    if ($gmt_opts || $genome_opts) {
        if ($self->git_add) {
            system("git add $gmt_opts $genome_opts");
            $self->status_message("Added .opts file(s): " . join(" ", $gmt_opts, $genome_opts));
            $self->status_message("Remember to commit the .opts file(s)!");
        }
        elsif ($self->git_commit) {
            system("git commit -m 'genome completion updated opts files' $gmt_opts $genome_opts");
            $self->status_message("Committed .opts file(s): " . join(" ", $gmt_opts, $genome_opts));
        }
    }


    return 1;
}

1;
