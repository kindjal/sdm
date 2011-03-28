
package System::Disk::Array::Command::Delete;

use strict;
use warnings;

use System;

use Smart::Comments -ENV;

class System::Disk::Array::Command::Delete {
    is => 'System::Command::Base',
    has => [
        array => { is => 'System::Disk::Array', shell_args_position => 1 },
    ],
};


sub help_brief {
    return 'deletes arrays';
}

sub help_synopsis {
    return <<EOS
Delete arrays, but tries to notify the user of the implications.
EOS
}

sub help_detail {
    return <<EOS
Delete arrays, but tries to notify the user of the implications.
EOS
}

=head2 execute
Execute S:D:A:C:Delete() deletes Volumes and handles order of ops
=cut
sub execute {
    my $self = shift;

    unless ($self->array) {
        $self->error_message("Please specify array to delete");
        return;
    }
    my $array = $self->array;

    # Before we remove the Array, we must remove its connection to Hosts.
    foreach my $mapping ($array->mappings) {
        $mapping->delete() or die
            "Failed to remove host-array mapping: $!";
    }

    return $array->delete();
}

1;
