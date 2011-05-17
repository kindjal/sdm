package SDM::Completion::Command::Update;

use strict;
use warnings;

class SDM::Completion::Command::Update {
    is => 'SDM::Command::Base',
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
    $help_detail .= " * SDM/Command.pm.opts\n";

    return $help_detail;
}

sub execute {
    my $self = shift;
    $self->error_message("Not yet implemented");
    return;
}

1;
