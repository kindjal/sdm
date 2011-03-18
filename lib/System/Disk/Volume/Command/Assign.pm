
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

sub _prep_filesystem {
    my $self = shift;
    my ($volume,$group) = @_;
    ### S:D:V->_prep_filesystem: $self
    $self->warning_message("Assign " . $volume->mount_path . " to " . $group->name);
    $self->error_message("Not yet implemented");
    return;

    # Set up the filesystem.
    unless (-w $volume->mount_path) {
        $self->error_message("Mount path is not writable: " . $volume->mount_path);
        return;
    }

    #open(FH,'>',$volume->mount_path) or die "Can't open touchfile " . $volume->mount_path;
    #close();
    #my $subdir = $volume->mount_path . "/" . 
    #mkdir $volume->mount_path . "/info"
}

sub execute {
    my $self = shift;
    my $disk_group = uc($self->disk_group);
    ### S:D:V->assign: $self

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

    $self->_prep_filesystem( $volume, $group );

    # FIXME: turn this on when prep_filesystem is done
    # Set the assignment in the Volume table after the filesystem is correct.
    #$volume->disk_group($disk_group);
}

1;
