
package System::Disk::Filer;

use strict;
use warnings;

use System;
use Date::Manip;
use Smart::Comments -ENV;

class System::Disk::Filer {
    table_name => 'DISK_FILER',
    id_by => [
        name            => { is => 'Text', len => 255 },
    ],
    has_optional => [
        comments        => { is => 'Text', len => 255 },
        filesystem      => { is => 'Text', len => 255 },
        created         => { is => 'DATE' },
        last_modified   => { is => 'DATE' },
        status          => { is => 'UnsignedInteger' },
    ],
    has_many_optional => [
        hostmappings    => { is => 'System::Disk::FilerHostBridge', reverse_as => 'filer' },
        host            => { is => 'System::Disk::Host', via => 'hostmappings', to => 'host'  },
        hostname        => { via => 'host', to => 'hostname' },
        arrayname       => { via => 'host', to => 'arrayname' },
        exports         => { is => 'System::Disk::Export', via => 'host' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

=head2 is_current
Check the given Filer's last_modified time and compare it to time().  If the difference is
greater than host_maxage, the Filer is considered "stale".
=cut
sub is_current {
    my $self = shift;
    my $host_maxage = shift;
    # Default max age is 15 days.
    $host_maxage = 1296000 unless (defined $host_maxage and $host_maxage > 0);
    ### Filer->is_current: $host_maxage
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

    ### Filer->is_current date0: $date0
    ### Filer->is_current date1: $date1
    ### Filer->is_current delta: $delta
    ### Filer->is_current host_maxage: $host_maxage

    return 0 if (! defined $delta);
    return 1
        if $delta > $host_maxage;
    return 0;
}

=head create
Create method for Filer sets created attribute.
=cut
sub create {
    my $self = shift;
    my (%params) = @_;
    unless ($params{name}) {
        $self->error_message("No name given for Filer");
        return;
    }
    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    return $self->SUPER::create( %params );
}

sub delete {
    my $self = shift;
    ### Filer->delete: $self

    my @volumes = System::Disk::Volume->get( filername => $self->name );

    # Before we remove the Filer, we must remove its Mounts and Exports
    ### 1
    foreach my $export ( $self->exports ) {
    ### 2
        # Remove any Mounts of this Export
        foreach my $mount (System::Disk::Mount->get( export_id => $export->id ))  {
    ### 3
            ### Remove mount: $mount
            $self->warning_message("Remove Mount " . $mount->mount_path . " for Export " . $export->id);
            $mount->delete() or
                die "Failed to remove Mount '" . $mount->id . "' for Filer: " . $self->name;
        }
    ### 4
        ### Remove export: $export
        $self->warning_message("Remove Export " . $export->id . " for Filer " . $self->name);
        $export->delete() or
            die "Failed to remove Export for Filer: " . $self->name;
    }
    ### 5

    ### Filer delete();
    $self->warning_message("Remove Filer " . $self->name);
    my $res = $self->SUPER::delete();

    # After we remove a filer, we iterate through Volumes that claimed to have been mounted
    # on this filer and see if they're now orphans.
    foreach my $volume (@volumes) {
        if ($volume->is_orphan) {
            ### Remove volume: $volume
            $self->warning_message("Removing now orphaned Volume: " . $volume->mount_path);
            $volume->delete();
        }
    }

    return $res;
}

1;
