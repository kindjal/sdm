
package SDM::Disk::Volume::Set::View::Group::Json;

=head2 SDM::Disk::Volume::Set::View::Group::Json
This class' job is to redefine JSON output.  Our diskusage.html
page uses DataTables that wants JSON with aaData and other attributes.
=cut

use strict;
use warnings;

use SDM;


class SDM::Disk::Volume::Set::View::Group::Json {
    is => 'UR::Object::Set::View::Default::Json',
};

=head2 aaData
Build the aaData for jQuery DataTables.  This is a list of table row data.
=cut
sub aaData {
    my $self = shift;
    my @data;
    my $subject = $self->subject;
    return unless ($subject);

    my @disk_groups = $subject->members( -group_by => [ 'disk_group' ], -order_by => [ 'disk_group' ] );
    return unless (@disk_groups);

    foreach my $item ( @disk_groups ) {
        my $group = $item->disk_group ? $item->disk_group : "unknown",
        my $capacity = 0;
        my $total_kb = $item->sum('total_kb');
        my $used_kb = $item->sum('used_kb');
        if ( $total_kb ) {
            $capacity = $used_kb / $total_kb * 100;
        }
        push @data, [
            $group,
            $total_kb,
            $used_kb,
            $capacity,
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
