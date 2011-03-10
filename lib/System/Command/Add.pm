package System::Command::Add;

use strict;
use warnings;

use System;

require Carp;
use Data::Dumper 'Dumper';

class System::Command::Add {
    is => 'System::Command::Base',
    is_abstract => 1,
    doc => 'CRUD add command class.',
};

sub _target_class { Carp::confess('Please use CRUD or implement _target_class in '.$_[0]->class); }
sub _name_for_objects { Carp::confess('Please use CRUD or implement _name_for_objects in '.$_[0]->class); }

sub sub_command_sort_position { .1 };

sub help_brief {
    return 'add '.$_[0]->_name_for_objects;
}

sub help_detail {
    return 'HELP IN PROGRESS';
}

sub execute {
    my $self = shift;

    $self->status_message('Add'.$self->_name_for_objects);

    my $class = $self->class;
    my @properties = grep { $_->class_name eq $class } $self->__meta__->property_metas;
    my %attrs;
    for my $property ( @properties ) {
        my $property_name = $property->property_name;
        my @values;
        if ($property_name eq 'created') {
            push @values, Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
        } else {
            @values = $self->$property_name;
        }
        next if not defined $values[0];
        if ( $property->is_many ) {
            $attrs{$property_name} = \@values;
        }
        else {
            $attrs{$property_name} = $values[0];
        }
    }
    $self->status_message(Dumper(\%attrs));

    my $target_class = $self->_target_class;
    my $obj = $target_class->create(%attrs);
    if ( not $obj ) {
        $self->error_message('Could not create '.$target_class);
        return;
    }

    $self->status_message('Create: '.$obj->id);

    return 1;
}

1;
