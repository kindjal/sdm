
package System::Disk::Volume::Command::Assign;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command::Assign {
    is  => 'System::Command::Base',
    doc => 'assign volumes to groups',
    has => [
        volume => { is => 'System::Disk::Volume', shell_args_position => 1 },
        group  => { is => 'System::Disk::Group',  shell_args_position => 2 },
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
    my ($path,$group) = @_;
    ### Volume->_prep_filesystem: $self
    ###   path: $path
    ###   group: $group
    $self->warning_message("Assign $path to " . $group->name);
    $self->error_message("Not yet implemented");
    return;

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
    unless ($dir) {
        $self->error_message("Group $group has no subdirectory attribute");
        return;
    }
    $dir =~ s/_.*//;
    $dir = "$path/$dir";
    if (! $self->_create_dir($dir)) {
        unlink($file);
        return;
    }
    if (! $self->_set_mode($dir, $$group->unix_uid, $group->unix_gid, $group->permissions)) {
        rmdir($dir);
        unlink($file);
        return;
    }

    # Create subgroup dirs
    foreach my $subgroup ( System::Disk::Group->get( parent_group => $group->name ) ) {
        unless ($self->_prep_filesystem( $group->subdirectory, $subgroup )) {
            $self->error_message("Error prepping group directory: " . $group->name);
            return;
        }
    }

    return 1;
}

sub execute {
    my $self = shift;
    ### Volume->assign: $self

    unless ($self->_prep_filesystem( $self->volume->mount_path, $self->group )) {
        $self->error_message("Error prepping group directory: " . $self->group->name);
        return;
    }

    # FIXME: turn this on when prep_filesystem is done
    # Set the assignment in the Volume table after the filesystem is correct.
    #$self->volume->disk_group($group->name);
}

1;
