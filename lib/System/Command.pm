package System::Command;

use strict;
use warnings;

use System;

class System::Command {
    is => 'System::Command::Base',
};

my @SUB_COMMANDS = qw/ disk /;

our %SUB_COMMAND_CLASSES =
    map {
        my @words = split(/-/,$_);
        my $class = join("::",
            'System',
            join('',map{ ucfirst($_) } @words),
            'Command'
        );
        ($_ => $class);
    }
    @SUB_COMMANDS;

our @SUB_COMMAND_CLASSES = map { $SUB_COMMAND_CLASSES{$_} } @SUB_COMMANDS;

for my $class ( @SUB_COMMAND_CLASSES ) {
    eval("use $class;");
    die $@ if $@; 
}

sub execute_with_shell_params_and_exit {
    my $class = shift;
    return $class->SUPER::execute_with_shell_params_and_exit(@_);
}

sub command_name {
    return 'system';
}

sub command_name_brief {
    return 'system';
}

sub is_sub_command_delegator {
    return 1;
}

sub sorted_sub_command_classes {
    return @SUB_COMMAND_CLASSES;
}

sub sub_command_classes {
    return @SUB_COMMAND_CLASSES;
}

sub class_for_sub_command {
    my $self = shift;
    my $sub_command = shift;
    return $SUB_COMMAND_CLASSES{$sub_command};
}

1;
