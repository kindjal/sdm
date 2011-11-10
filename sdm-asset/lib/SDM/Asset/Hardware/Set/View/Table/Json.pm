
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
        my $class = $item->__meta__->class_name;
        my @properties = $class->__meta__->properties;
        my @attributes = map { $_->property_name } @properties;
        # sort so we have the same order as Html.pm
        @attributes = sort @attributes;
        # id must be first
        @attributes = grep { ! /id/ } @attributes;
        unshift @attributes,'id';
        my @bdata = map { $item->$_ } @attributes;
        push @data, [ @bdata] ;
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
