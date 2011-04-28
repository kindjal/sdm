
package System::Disk::Volume::View::Status::Cgi;

use strict;
use warnings;

use System;

class System::Disk::Volume::View::Status::Cgi {
    is => 'System::Disk::View::Cgi'
};

=head2 _fnColumnToField
This maps a column in DataTables to a UR::Object attribute.
=cut
sub _fnColumnToField {
    my $self = shift;
    $self->{logger}->debug("_fnColumnToField: map DataTable column to UR::Object attribute");
    my $i = shift;

    # Note: we could have used an array, but for dispatching purposes, this is
    # more readable. These are the column names on the disk summary datatable.
    my %dispatcher = (
            # column => 'rowname',
            0 => 'mount_path',
            1 => 'total_kb',
            2 => 'used_kb',
            3 => 'capacity',
            4 => 'disk_group',
            5 => 'filername',
            6 => 'last_modified',
            );

    die("No such row index defined: $i") unless exists $dispatcher{$i};

    return $dispatcher{$i};
}

=head2 _build_result_set
Get the set of Volumes represented by a DataTables query.
=cut
sub _build_result_set {
    my ($self,$q) = @_;
    $self->{logger}->debug("_build_result_set: fetch UR::Objects and return a UR::Object::Set");

    my $param = {};
    my @where = $self->_build_where_param($q);
    if (scalar @where) {
        $param->{ -or } = \@where;
    }

    my @result = System::Disk::Volume->get( $param );
    return @result;
}

=head2 _build_aadata
Order and sort our UR::Object::Set as well as applying some modifiers and transformations.
=cut
sub _build_aadata {
    my $self = shift;
    $self->{logger}->debug("_build_aadata: convert a UR::Object::Set");
    my $query = shift;
    my @results = @_;
    return unless (@results and $results[0]->isa( 'System::Disk::Volume') );
    my @data;
    foreach my $item ( @results ) {
        my $capacity = 0;
        if ($item->total_kb) {
            $capacity = $item->used_kb / $item->total_kb * 100;
        }
        my @filernames = $item->filername;
        my $filername = join(',',@filernames );
        $filername = 'unknown' if (! defined $filername);
        push @data, [
            $item->mount_path,
            $item->total_kb,
            $item->used_kb,
            $capacity,
            $item->disk_group ? $item->disk_group : 'unknown',
            $filername,
            $item->last_modified ? $item->last_modified : 'unknown'
        ];
    }

    my @sorted_data = $self->_sorter($query,@data);
    return @sorted_data;
}

=head2 _prettify_aadata
Adds commas and readability stuff to our aaData.
=cut
sub _prettify_aadata {
    my $self = shift;
    $self->{logger}->debug("_prettify_aadata");
    my @data = @_;
    return unless (@data and scalar @{ $data[0] } );
    @data = map { [
         $_->[0],
         $self->_commify($_->[1]) . " (" . $self->_short($_->[1]) . ")",
         $self->_commify($_->[2]) . " (" . $self->_short($_->[2]) . ")",
         sprintf("%d %%", $_->[3]),
         $_->[4],
         $_->[5],
         $_->[6],
    ] } @data;
    return @data;
}

1;
