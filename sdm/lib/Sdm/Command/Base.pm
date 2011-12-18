package Sdm::Command::Base;

use strict;
use warnings;
use Sdm;
use Log::Log4perl qw(:easy);

class Sdm::Command::Base {
    is          => 'Command::V2',
    is_abstract => 1,
    has_optional => [
        loglevel    => { is => 'Text', default => 'INFO' },
        logfile     => { is => 'Text', default => 'STDERR' },
    ],
};

=head2 _prepare_logger
Turn on logging with Log::Log4perl
=cut
sub _prepare_logger {
    my $self = shift;
    Log::Log4perl->easy_init(
        { level => $self->{loglevel}, category => __PACKAGE__, file => $self->{logfile} }
    );
    $self->{logger} = Log::Log4perl->get_logger();
}

sub logger {
    my $self = shift;
    return $self->{logger};
}

=head2 create
We override UR/lib/Command/V2.pm to trigger _prepare_logger
=cut
sub create {
    my $class = shift;
    my ($rule,%extra) = $class->define_boolexpr(@_);
    my @params_list = $rule->params_list;
    my $self = $class->SUPER::create(@params_list, %extra);
    $self->_prepare_logger();
    return unless $self;

    # set non-optional boolean flags to false.
    for my $property_meta ($self->_shell_args_property_meta) {
        my $property_name = $property_meta->property_name;
        if (!$property_meta->is_optional and !defined($self->$property_name)) {
            if (defined $property_meta->data_type and $property_meta->data_type =~ /Boolean/i) {
                $self->$property_name(0);
            }
        }
    }

    return $self;
}

=head2 _ask_user_question
This should go back into UR/lib/Command/V2.pm
=cut
sub _ask_user_question {
    my $self = shift;
    my $question = shift;    my $timeout = shift;
    my $valid_values = shift || "yes|no";
    my $default_value = shift || undef;
    my $pretty_valid_values = shift || $valid_values;
    $valid_values = lc($valid_values);
    my $input;
    $timeout = 60 unless(defined($timeout));

    local $SIG{ALRM} = sub { print STDERR "Exiting, failed to reply to question '$question' within '$timeout' seconds.\n"; exit; };
    print STDERR "\n$question\n";
    print STDERR "Reply with $pretty_valid_values: ";

    unless ($self->_can_interact_with_user) {
        die $self->error_message("Attempting to ask user question but cannot interact with user!");
    }
    alarm($timeout) if ($timeout);
    chomp($input = <STDIN>);    alarm(0) if ($timeout);

    print STDERR "\n";

    if(lc($input) =~ /^$valid_values$/) {
        return lc($input);
    }
    elsif ($default_value) {
        return $default_value;
    }
    else {
        $self->error_message("'$input' is an invalid answer to question '$question'\n\n");
        return;
    }
}

=head2 _can_interact_with_user
This should go back into UR/lib/Command/V2.pm
=cut
sub _can_interact_with_user {
    my $self = shift;
    if ( -t STDERR ) {
        return 1;
    }
    else {
        return 0;
    }
}

1;

