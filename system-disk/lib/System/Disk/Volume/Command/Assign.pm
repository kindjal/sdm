
package System::Disk::Volume::Command::Assign;

use strict;
use warnings;

use System;
use Smart::Comments -ENV;
# For EUID
use English '-no_match_vars';

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

    if (! chmod($mode, $path)) {
        $self->error_message("failed to chmod directory $path: $mode: $!");
        rmdir($path);
        return;
    }
    printf "chmod %o $path\n", $mode;

    unless ($EUID == 0) {
        $self->warning_message("EUID != 0, skipping _set_mode: $path $owner:$group");
        return 1;
    }

    if (! chown($owner, $group, $path)) {
        $self->error_message("failed to chown $path $owner:$group: $!");
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
        $self->error_message("failed to create directory: $path: $!");
        return;
    }

    return 1;
}


sub _prep_filesystem {
    my $self = shift;
    my ($path,$group) = @_;

    $self->warning_message("assigning $path to " . $group->name);

    unless (-w $path) {
        $self->error_message("mount path is not writable: $path");
        return;
    }

    my @assignments = glob("$path/DISK_*");
    if (@assignments) {
        $self->error_message("directory is already assigned: @assignments");
        return;
    }

    if (! $self->_set_mode($path, 0, 0, 0755)) {
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

    my $dir = $group->subdirectory;
    unless ($dir) {
        $self->error_message("group $group has no subdirectory attribute");
        return;
    }
    $dir =~ s/_.*//;
    $dir = "$path/$dir";
    if (! $self->_create_dir($dir)) {
        unlink($file);
        return;
    }
    if (! $self->_set_mode($dir, $group->unix_uid, $group->unix_gid, $group->permissions)) {
        rmdir($dir);
        unlink($file);
        return;
    }

    return 1;
}

sub execute {
    my $self = shift;

    unless ($self->_prep_filesystem( $self->volume->mount_path, $self->group )) {
        $self->error_message("Error prepping group directory: " . $self->group->name);
        return;
    }

    $self->volume->disk_group($self->group->name);
}

1;
