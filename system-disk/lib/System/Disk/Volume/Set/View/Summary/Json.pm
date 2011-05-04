
package System::Disk::Volume::Set::View::Summary::Json;

=head2 System::Disk::Volume::Set::View::Summary::Json;
This class' job is to redefine JSON output.  Our diskusage.html
page uses DataTables that wants JSON with aaData and other attributes.
=cut

use strict;
use warnings;

use System;

class System::Disk::Volume::Set::View::Summary::Json {
    is => 'UR::Object::Set::View::Default::Json',
};

=head2 _jsobj
Override the normal JSON object with one suitable for jQuery DataTables.
We do this because we're bypassing the XSL layer expected by UR.
=cut
sub _jsobj {
    my $self = shift;

    my $subject = $self->subject();
    return '' unless $subject;

    my $total_kb = $subject->sum('total_kb');
    my $used_kb = $subject->sum('used_kb');
    my $capacity = 0;
    if ($total_kb) {
        $capacity = $used_kb / $total_kb * 100;
    }

    my $ordered_set = $subject->members( -group_by => [ 'last_modified' ], -order_by => [ 'last_modified' ] );
    my $r = pop @{ [ $ordered_set->members ] };
    my $last_modified = "0000:00:00:00:00:00";
    $last_modified = $r->{last_modified} ? $r->{last_modified} : $last_modified;

    my $jsobj = {
        total_kb => $subject->sum('total_kb'),
        used_kb => $subject->sum('used_kb'),
        capacity => $capacity,
        last_modified => $last_modified,
    };

    return $jsobj;
}

1;
