
package System::Disk::Volume::Set::View::Status::Json;

=head2 System::Disk::Volume::Set::View::Status::Json
This class' job is to redefine JSON output.  Our diskusage.html
page uses DataTables that wants JSON with aaData and other attributes.
=cut

use strict;
use warnings;

use System;


class System::Disk::Volume::Set::View::Status::Json {
    is => 'UR::Object::Set::View::Default::Json',
};

=head2 aaData
Build the aaData for jQuery DataTables.  This is a list of table row data.
=cut
sub aaData {
    my $self = shift;
    my @data;
    my $subject = $self->subject;
    return [] unless ($subject);

    foreach my $item ( $subject->members ) {
        my $capacity = 0;
        if ( $item->{total_kb} ) {
            $capacity = $item->{used_kb} / $item->{total_kb} * 100;
        }
        push @data, [
            $item->{mount_path},
            $item->{physical_path},
            $item->{total_kb},
            $item->{used_kb},
            $item->{status},
            $capacity,
            $item->{filername},
            $item->{disk_group},
            $item->{last_modified} ? $item->{last_modified} : "0000-00-00 00:00:00",
        ];
    }
    return @data;
}

=head2 _jsobj
Override the normal JSON object with one suitable for jQuery DataTables.
We do this because we're bypassing the XSL layer expected by UR.
=cut
sub _jsobj {
    my $self = shift;

    my $subject = $self->subject();
    return '' unless $subject;

    my $jsobj = {
        aaData => [ $self->aaData ],
        iTotalRecords => $subject->count,
        iTotalDisplayRecords => $subject->count,
        sEcho => 1,
    };

    return $jsobj;
}

1;
