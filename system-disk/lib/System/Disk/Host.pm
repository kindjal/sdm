
package System::Disk::Host;

use strict;
use warnings;

use System;
use Date::Manip;

class System::Disk::Host {
    table_name => 'disk_host',
    id_by => [
        hostname        => { is => 'Text', len => 255 },
    ],
    has_optional => [
        status          => { is => 'UnsignedInteger', default => 0 },
        os              => { is => 'Text', len => 255 },
        comments        => { is => 'Text', len => 255 },
        location        => { is => 'Text', len => 255 },
        created         => { is => 'DATE' },
        last_modified   => { is => 'DATE' },
    ],
    has_many_optional => [
        arraymappings   => { is => 'System::Disk::HostArrayBridge', reverse_as => 'host' },
        array           => { is => 'System::Disk::Array', via => 'arraymappings' },
        arrayname       => { via => 'array', to => 'name' },
        filermappings   => { is => 'System::Disk::FilerHostBridge', reverse_as => 'host' },
        filer           => { is => 'System::Disk::Filer', via => 'filermappings', to => 'filer' },
        filername       => { via => 'filer', to => 'name' },
        #exports         => { is => 'System::Disk::Export', reverse_as => 'host' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

=head2 assign
Assign the current host to a named filer.
=cut
sub assign {
    my $self = shift;
    my $filername = shift;
    unless ($filername) {
        $self->error_message("specify a filer name to assign this host to");
        return;
    }
    my $filer = System::Disk::Filer->get( name => $filername );
    unless ($filer) {
        $self->error_message("the filer named '$filername' is unknown");
        return;
    }
    my $res = System::Disk::FilerHostBridge->create( host => $self, filer => $filer );
    return $res;
}

=head2 is_current
Check the given Host's last_modified time and compare it to time().  If the difference is
greater than host_maxage, the Host is considered "stale".
=cut
sub is_current {
    my $self = shift;
    my $host_maxage = shift;
    # Default max age is 15 days.
    $host_maxage = 1296000 unless (defined $host_maxage and $host_maxage > 0);
    ### Host->is_current: $host_maxage
    return 0 if (! defined $self->last_modified);
    return 0 if ($self->last_modified eq "0000-00-00 00:00:00");

    my $date0 = $self->last_modified;
    $date0 =~ s/[- :]//g;
    $date0 = ParseDate($date0);
    return 0 if (! defined $date0);

    my $err;
    my $date1 = ParseDate( Date::Format::time2str(q|%Y%m%d%H:%M:%S|, time() ) );
    my $calc = DateCalc($date0,$date1,\$err);

    die "Error in DateCalc: $date0, $date1, $err\n" if ($err);
    die "Error in DateCalc: $date0, $date1, $err\n" if (! defined $calc);

    my $delta = int(Delta_Format($calc,0,'%st'));

    ### Host->is_current date0: $date0
    ### Host->is_current date1: $date1
    ### Host->is_current delta: $delta
    ### Host->is_current host_maxage: $host_maxage

    return 0 if (! defined $delta);
    return 1
        if $delta > $host_maxage;
    return 0;
}

=head2 create
Create method for Host sets created attribute.
=cut
sub create {
    my $self = shift;
    my (%params) = @_;
    unless ($params{hostname}) {
        $self->error_message("No hostname given for Host");
        return;
    }
    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    return $self->SUPER::create( %params );
}

=head2 delete
Delete Hosts and relationships
=cut
sub delete {
    my $self = shift;
    # Before a Host can be deleted, remove entries from relationship tables.
    foreach my $mapping ($self->arraymappings) {
        $mapping->delete or die "Failed to remove Host-Array mapping " . $mapping->id;
    }
    foreach my $mapping ($self->filermappings) {
        $mapping->delete or die "Failed to remove Host-Filer mapping " . $mapping->id;
    }
    return $self->SUPER::delete();
}

1;
