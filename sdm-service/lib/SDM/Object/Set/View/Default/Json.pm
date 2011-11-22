
package SDM::Object::Set::View::Default::Json;

use strict;
use warnings;

use SDM;

class SDM::Object::Set::View::Default::Json {
    is => 'UR::Object::Set::View::Default::Json'
};

sub _generate_content {
    my $self = shift;
    return $self->_json->allow_blessed->encode($self->_jsobj);
}

=head2 _jsobj
Override the normal JSON object with one suitable for jQuery DataTables.
We do this because we're bypassing the XSL layer expected by UR.
=cut
sub _jsobj {
    my $self = shift;

    my $subject = $self->subject();
    return '' unless $subject =~ /::Set/;

    my @aData;
    foreach my $member ($subject->members) {
        my %args = (
            subject_class_name => $self->subject_class_name,
            perspective => 'default',
            toolkit => 'json',
        );
        $args{aspects} = $self->default_aspects if ($self->default_aspects);
        my $v = $member->create_view(%args);
        my @data = $v->aspects;
        @data = map { $v->_generate_content_for_aspect($_) } @data;
        push @aData, [ @data ] ;
    }

    my $jsobj = {
        aaData => [ @aData ],
        iTotalRecords => $subject->count,
        iTotalDisplayRecords => $subject->count,
        sEcho => 1,
    };

    return $jsobj;
}

1;
