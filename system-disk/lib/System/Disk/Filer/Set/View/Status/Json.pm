
package System::Disk::Filer::Set::View::Status::Json;

=head2 System::Disk::Filer::Set::View::Status::Json
This class' job is to redefine JSON output.  Our diskusage.html
page uses DataTables that wants JSON with aaData and other attributes.
=cut

use strict;
use warnings;

use System;


class System::Disk::Filer::Set::View::Status::Json {
    is => 'UR::Object::Set::View::Default::Json',
    has_constant => [
        default_aspects => {
            is => 'ARRAY',
            value => [
                { name => 'aaData', },
                { name => 'iTotalRecords' },
                { name => 'iTotalDisplayRecords' },
                { name => 'sEcho' },
            ]
        }
    ]
};

=head2 _generate_content_for_aspect
Override the base class method so that we can properly handle the aaData list attribute
we need.  We return an array ref if is_many, which aaData is.
See System::Disk::Filer::Set for that.
=cut
sub _generate_content_for_aspect {
    my $self = shift;
    my $aspect = shift;

    my $subject = $self->subject;
    my $aspect_name = $aspect->name;
    my $aspect_meta = $self->subject_class_name->__meta__->property($aspect_name);

    my @value;
    @value = $subject->$aspect_name;

    if ($aspect_meta->is_many) {
        return \@value;
    } else {
        return shift @value;
    }
}

1;
