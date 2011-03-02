package System::Disk::Volume::Command::Create;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command::Create {
    is => 'System::Command::Base',
    has => [
        filer => { is => 'System::Disk::Filer', id_by => 'filername', constraint_name => 'VOLUME_FILER_FK' },
        mount_path => { is  => 'Text' },
        physical_path => { is  => 'Text' },
        total_kb => { is  => 'Number', default => 0 },
        used_kb => { is  => 'Number', default => 0 }
    ],
    has_optional => [
        disk_group => { is => 'System::Disk::Group', id_by => 'name', constraint_name => 'VOLUME_GROUP_FK' },
        created => { is  => 'Date', },
        last_modified => { is  => 'Date', }
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
        filer         => $self->filer,
        mount_path    => $self->mount_path,
        physical_path => $self->physical_path,
        total_kb      => $self->total_kb,
        used_kb       => $self->used_kb,
    );
    $params{disk_group} = $self->disk_group if defined $self->disk_group;
    $params{created} = $self->created if defined $self->created;
    $params{last_modified} = $self->last_modified if defined $self->last_modified;

    eval {
      System::Disk::Volume->create(%params);
    };
    if ($@) {
        Carp::confess "Could not create volume: $@";
    }

    return 1;
}

1;
