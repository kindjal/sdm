
package SDM::Asset::Hardware::Set::View::Table::Json;

use strict;
use warnings;

use SDM;

class SDM::Asset::Hardware::Set::View::Table::Json {
    is => 'UR::Object::Set::View::Default::Json',
};

=head2 aaData
Build the aaData for jQuery DataTables.  This is a list of table row data.
=cut
sub aaData {
    my $self = shift;
    my @data;

    my $subject = $self->subject();
    return [] unless ($subject);

    foreach my $item ( $subject->members ) {
        push @data, [
            $item->manufacturer,
            $item->model,
            $item->serial,
            $item->created ? $item->created : "0000-00-00 00:00:00",
            $item->last_modified ? $item->last_modified : "0000-00-00 00:00:00",
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
