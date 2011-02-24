package System::Disk::Volume::Command::Create;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command::Create {
    is => 'System::Command::Base',
    has => [
        #subject_class_name  => {
        #    is_constant => 1,
        #    value => 'System::Disk::Volume',
        #},
        filer_id => {
            is  => 'Number',
            doc => 'The ID of the filer serving this volume',
        },
        mount_path => {
            is  => 'Text',
            doc => 'The path this volume is mounted at',
        },
        physical_path => {
            is  => 'Text',
            doc => 'The path this volume is exported from',
        },
        total_kb => {
            is  => 'Number',
            doc => 'Total KB in this volume',
        },
        used_kb => {
            is  => 'Number',
            doc => 'Used KB in this volume',
        }
    ],
    has_optional => [
        created => {
            is  => 'Date',
            doc => 'Date this volume was added',
        },
        last_modified => {
            is  => 'Date',
            doc => 'Date this volume was last modified',
        }
    ],
    doc => 'Creates a volume entry'
};

sub help_brief {
    return 'Creates a volume';
}

sub help_synopsis {
    return <<EOS
Creates a volume
EOS
}

sub help_detail {
    return <<EOS
This tool creates a volume.  Blah blah blah details blah.
EOS
}

sub execute {
    my $self = shift;
    my %params = (
        physical_path => $self->physical_path,
        mount_path    => $self->mount_path,
        filer_id      => $self->filer_id,
        total_kb      => $self->total_kb,
        used_kb       => $self->used_kb,
    );
    $params{created} = $self->created if defined $self->created;
    $params{last_modified} = $self->last_modified if defined $self->last_modified;

    my $volume = System::Disk::Volume->create(%params);
    unless ($volume) {
        Carp::confess "Could not create volume: $!";
    }

    return 1;
}

1;
