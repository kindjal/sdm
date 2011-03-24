
package System::Disk::Filer::Command::Delete;

use strict;
use warnings;

use System;

use Smart::Comments -ENV;

class System::Disk::Filer::Command::Delete {
    is => 'System::Command::Base',
    has => [
        filer => { is => 'System::Disk::Filer', shell_args_position => 1 },
    ],
};


sub help_brief {
    return 'deletes volumes';
}

sub help_synopsis {
    return <<EOS
Delete volumes and related exports and mounts when needed.
EOS
}

sub help_detail {
    return <<EOS
Delete volumes and related exports and mounts when needed.
EOS
}

=head2 execute
Execute S:D:F:C:Delete() deletes Volumes and handles order of ops
=cut
sub execute {
    my $self = shift;

    unless ($self->filer) {
        $self->error_message("Please specify filer to delete");
        return;
    }
    my $filer = $self->filer;

    # Before we remove the Filer, we must remove its Mounts and Exports
    #foreach my $export ( $filer->exports ) {
    foreach my $export ( System::Disk::Export->get ( filername => $filer->name )) {
        # Remove any Mounts of this Export
        foreach my $mount (System::Disk::Mount->get( export_id => $export->id ))  {
            $self->warning_message("Remove Mount " . $mount->mount_path . " for Export " . $export->id);
            $mount->delete() or
                die "Failed to remove Mount '" . $mount->id . "' for Filer: " . $filer->name;
        }
        $self->warning_message("Remove Export " . $export->id . " for Filer " . $filer->name);
        $export->delete() or
            die "Failed to remove Export for Filer: " . $filer->name;
    }
    $self->warning_message("Remove Filer " . $filer->name);
    $filer->delete();

    $DB::single = 1;

    return;
}

1;
