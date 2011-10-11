
package SDM::Disk::Fileset::Set::View::Group::Json;

=head2 SDM::Disk::Fileset::Set::View::Group::Json
This class' job is to redefine JSON output.  Our diskusage.html
page uses DataTables that wants JSON with aaData and other attributes.
=cut

use strict;
use warnings;

use SDM;

class SDM::Disk::Fileset::Set::View::Group::Json {
    is => 'UR::Object::Set::View::Default::Json',
};

=head2 aaData
Build the aaData for jQuery DataTables.  This is a list of table row data.
=cut
sub aaData {
    my $self = shift;
    my @data;

    my $subject = $self->subject;
    if (not $subject or not $subject =~ /::Set/) {
        $self->error_message(__PACKAGE__ . " illegally asked for aaData on an object that is not a UR::Object::Set");
        return;
    }

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

    my @aaData = $self->aaData;
    my $jsobj = {
        aaData => [ @aaData ],
        iTotalRecords => $#aaData + 1,
        iTotalDisplayRecords => $#aaData + 1,
        sEcho => 1,
    };

    return $jsobj;
}

1;
