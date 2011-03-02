package System::Disk::Group::Command::Create;

use strict;
use warnings;

use System;

class System::Disk::Group::Command::Create {
    is => 'System::Command::Base',
    has => [
        name            => { is => 'Text', len => 255 },
        permissions     => { is => 'UnsignedInteger' },
        sticky          => { is => 'UnsignedInteger' },
        unix_gid        => { is => 'UnsignedInteger' },
        unix_uid        => { is => 'UnsignedInteger' },
    ],
    has_optional => [
        created         => { is => 'DATE' },
        last_modified   => { is => 'DATE' },
        parent_group    => { is => 'Text', len => 255 },
        subdirectory    => { is => 'Text', len => 255 },
        username        => { is => 'Text', len => 255 },
    ],
};

sub help_brief {
    return 'Creates a group';
}

sub help_synopsis {
    return <<EOS
Creates a group
EOS
}

sub help_detail {
    return <<EOS
This tool creates a group.  Blah blah blah details blah.
EOS
}

sub execute {
    my $self = shift;
    my %params = (
        name => $self->name,
        permissions => $self->permissions,
        sticky => $self->sticky,
        unix_gid => $self->unix_gid,
        unix_uid => $self->unix_uid,
    );
    $params{parent_group} = $self->parent_group if defined $self->parent_group;
    $params{subdirectory} = $self->subdirectory if defined $self->subdirectory;
    $params{username} = $self->username if defined $self->username;

    eval {
        System::Disk::Group->create(%params);
    };
    if ($@) {
        Carp::confess "Could not create group: $!";
    }

    return 1;
}

1;
