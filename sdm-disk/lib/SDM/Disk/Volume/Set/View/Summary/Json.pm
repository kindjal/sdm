
package SDM::Disk::Volume::Set::View::Summary::Json;

=head2 SDM::Disk::Volume::Set::View::Summary::Json;
This class' job is to redefine JSON output.  Our diskusage.html
page uses DataTables that wants JSON with aaData and other attributes.
=cut

use strict;
use warnings;

use SDM;

class SDM::Disk::Volume::Set::View::Summary::Json {
    is => 'UR::Object::Set::View::Default::Json',
};

=head2 _jsobj
Override the normal JSON object with one suitable for jQuery DataTables.
We do this because we're bypassing the XSL layer expected by UR.
=cut
sub _jsobj {
    my $self = shift;
    my $last_modified = "0000:00:00:00:00:00";
    my $jsobj = {
        total_kb => 0,
        used_kb => 0,
        capacity => 0,
        last_modified => $last_modified,
    };

    my $subject = $self->subject();
    return $jsobj unless $subject;

    my $total_kb = $subject->sum('total_kb');
    my $used_kb = $subject->sum('used_kb');
    my $capacity = 0;
    if ($total_kb) {
        $capacity = $used_kb / $total_kb * 100;
    }

    my @result_set;
    my @ordered_sets = $subject->members( -group_by => [ 'last_modified' ], -order_by => [ 'last_modified' ] );
    return $jsobj unless (@ordered_sets);
    foreach my $set (@ordered_sets) {
        push @result_set, pop @{ [ $set->members ] };
    }
    my $latest = pop @result_set;

    $last_modified = $latest->last_modified ? $latest->last_modified : $last_modified;

    $jsobj = {
        total_kb => $subject->sum('total_kb'),
        used_kb => $subject->sum('used_kb'),
        capacity => $capacity,
        last_modified => $last_modified,
    };

    return $jsobj;
}

1;
