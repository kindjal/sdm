
package System::Disk::Volume::Command::Assign;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command::Assign {
    is => 'System::Command::Base',
    doc => 'assign volumes to groups',
    has => [
        mount_path    => { is => 'Text' },
        disk_group    => { is => 'Text' },
    ],
};

sub _set_mode {
    my $self = shift;
    my ($path, $owner, $group, $mode) = @_;

    if (!chown($owner, $group, $path)) {
        $self->error_message("failed to chown $path $owner:$group");
        rmdir($path);
        return;
    }

    if (!chmod(oct($mode), $path)) {
        $self->error_message("failed to chmod directory $path: $mode");
        rmdir($path);
        return;
    }

    return 1;
}

sub _create_dir {
    my $self = shift;
    my ($path) = @_;

    if (-d $path) {
        $self->error_message("directory already exists: $path");
        return;
    }

    if (! mkdir($path)) {
        $self->error_message("failed to create directory: $path");
        return;
    }

    return 1;
}


sub _prep_filesystem {
    my $self = shift;
    my ($volume,$group) = @_;
    ### Volume->_prep_filesystem: $self
    $self->warning_message("Assign " . $volume->mount_path . " to " . $group->name);
    $self->error_message("Not yet implemented");
    return;

    my $path = $volume->mount_path;
    unless (-w $path) {
        $self->error_message("Mount path is not writable: " . $path);
        return;
    }

    my @assignments = glob("$path/DISK_*");
    if (@assignments) {
        # FIXME: prompt for re-assignment here.
        $self->error_message("directory is already assigned: @assignments");
        return;
    }

    if (! $self->_set_mode($path, 0, 0, '0755')) {
        $self->error_message("failed to set permissions on top level directory: $path");
        return;
    }

    my $file = "$path/DISK_" . uc($group->name);
    my $file_content = (split(' ', qx(who am i)))[0];
    my $fh = IO::File->new(">$file");
    if (!defined($fh)) {
        $self->error_message("failed to create file: $file");
        return;
    }
    $fh->print("$file_content\n");
    $fh->close;

    # FIXME: make subdirectory mandatory Group attribute
    my $dir = $group->subdirectory;
    $dir =~ s/_.*//;
    $dir = "$path/$dir";
    if (! $self->_create_dir($dir)) {
        unlink($file);
        return;
    }
    if (! $self->_set_mode($dir, $conf->{$group}{owner}, $conf->{$group}{gid}, $conf->{$group}{mode})) {
        rmdir($dir);
        unlink($file);
        return;
    }

    # Create subgroup dirs
    # FIXME

    return 1;
}

sub execute {
    my $self = shift;
    my $disk_group = uc($self->disk_group);
    ### Volume->assign: $self

    my $volume = System::Disk::Volume->get( mount_path => $self->{mount_path} );
    unless ($volume) {
        $self->error_message("There is no Volume for mount path: " . $self->{mount_path});
        return;
    }
    my $group = System::Disk::Group->get( name => $disk_group );
    unless ($group) {
        $self->error_message("There is no Group named: " . $disk_group);
        return;
    }

    unless ($self->_prep_filesystem( $volume, $group )) {
        $self->error_message("Error prepping group directory: " . $disk_group);
        return;
    }

    # FIXME: turn this on when prep_filesystem is done
    # Set the assignment in the Volume table after the filesystem is correct.
    #$volume->disk_group($disk_group);
}

1;
