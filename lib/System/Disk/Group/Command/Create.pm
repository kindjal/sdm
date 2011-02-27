package System::Disk::Group::Command::Create;

use strict;
use warnings;

use System;

class System::Disk::Group::Command::Create {
    is => 'System::Command::Base',
    has => [
        subject_class_name  => {
            is_constant => 1,
            value => 'System::Disk::Group',
        },
        show => { 
            default_value => 'group_id,name'
        },
        name            => { is => 'Text', len => 255 },
        permissions     => { is => 'UnsignedInteger' },
        sticky          => { is => 'UnsignedInteger' },
        unix_gid        => { is => 'UnsignedInteger' },
        unix_uid        => { is => 'UnsignedInteger' },
    ],
    has_optional => [
        last_modified   => { is => 'DATE' },
        parent_group_id => { is => 'Integer' },
        subdirectory    => { is => 'Text', len => 255 },
        username        => { is => 'Text', len => 255 },
    ],
};

sub help_brief {
    return 'Creates a volume';
}

sub help_synopsis {
    return 'Creates a volume';
}

sub help_detail {
    return <<EOS
This tool creates a volume.  Blah blah blah details blah.
EOS
}

sub execute {
    my $self = shift;
    my %params = (
        name => $self->name,
        permissions => $self->permissions,
        sticky => $self->permissions,
        unix_gid => $self->permissions,
        unix_uid => $self->permissions,
        parent_group_id => $self->permissions,
        subdirectory => $self->permissions,
        username => $self->permissions,
    );

    my $volume = System::Disk::Group->create(%params);
    unless ($volume) {
        Carp::confess "Could not create group: $!";
    }

    return 1;
}

1;
