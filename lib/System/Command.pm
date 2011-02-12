package System::Command;

use strict;
use warnings;

use System;

use Data::Dumper;
require File::Basename;

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

#$SUB_COMMAND_CLASSES{'tools'} = 'System::Model::Tools';

our @SUB_COMMAND_CLASSES = map { $SUB_COMMAND_CLASSES{$_} } @SUB_COMMANDS;

for my $class ( @SUB_COMMAND_CLASSES ) {
    eval("use $class;");
    die $@ if $@; 
}

sub execute_with_shell_params_and_exit {
    my $class = shift;
    #if ($ARGV[0] && $ARGV[0] eq 'tools') {
    #    # hack for our special lopsided namespace
    #    $Command::entry_point_class = 'System::Model::Tools';
    #    $Command::entry_point_bin = 'system tools';
    #}
    return $class->SUPER::execute_with_shell_params_and_exit(@_);
}

#< Command Naming >#
sub command_name {
    return 'system';
}

sub command_name_brief {
    return 'system';
}

#< Sub Command Stuff >#
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
