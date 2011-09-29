
package SDM::Disk::Filer;

use strict;
use warnings;

use SDM;
use Date::Manip;

class SDM::Disk::Filer {
    table_name => 'disk_filer',
    id_by => [
        name            => { is => 'Text' },
    ],
    has => [
        type            => {
            # Filer->type was invented to distinguish between Volumes and PolyserveVolumes,
            # which have different UNIQUEness constraints.  Only Polyserve is different at this time.
            is => 'Text',
            doc => 'Filer type',
            valid_values => ['gpfs','polyserve','netapp','vcf','nfs'],
        },
    ],
    has_optional => [
        comments        => { is => 'Text' },
        filesystem      => { is => 'Text' },
        created         => { is => 'DATE' },
        last_modified   => { is => 'DATE' },
        status          => { is => 'UnsignedInteger', default => 0 },
        gpfs_cluster_status_id => {
            is => 'Number',
            calculate_from => 'name',
            calculate => q| my @f = SDM::Gpfs::GpfsClusterStatus->get( filername => $name); return map { $_->id } @f; |,
        },
        gpfs_cluster_status => { is => 'SDM::Gpfs::GpfsClusterStatus', id_by => 'gpfs_cluster_status_id' },
        gpfs_cluster_config_id => {
            is => 'Number',
            calculate_from => 'name',
            calculate => q| my @f = SDM::Gpfs::GpfsClusterConfig->get( filername => $name); return map { $_->id } @f; |,
        },
        gpfs_cluster_config => { is => 'SDM::Gpfs::GpfsClusterConfig', id_by => 'gpfs_cluster_config_id' },
    ],
    has_many_optional => [
        hostmappings    => { is => 'SDM::Disk::FilerHostBridge', reverse_as => 'filer' },
        host            => { is => 'SDM::Disk::Host', via => 'hostmappings', to => 'host'  },
        hostname        => { is => 'Text', via => 'host', to => 'hostname' },
        # The obvious way to reference arraynames produces a list with duplicates
        #arrayname       => { via => 'host', to => 'arrayname' },
        # Use this calculation to produce a list of unique arraynames
        arrayname      => {
            is => 'Text',
            calculate => q/ my %h; foreach my $h ($self->host) { map { $h{$_} = 1 } $h->arrayname }; return keys %h; /
        },
    ],
    schema_name => 'Disk',
    data_source => 'SDM::DataSource::Disk',
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

    my @missing;
    foreach my $attr ( $self->__meta__->properties ) {
        next if ($attr->is_optional or $attr->via or $attr->is_calculated or $attr->is_id or $attr->id_by or defined $attr->default_value);
        push @missing, $attr->property_name unless (exists $params{$attr->property_name});
    }
    if (@missing) {
        $self->error_message("missing required attributes in create(): " . join(" ",@missing));
        return;
    }

    $params{created} = Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time());
    return $self->SUPER::create( %params );
}

sub delete {
    my $self = shift;

    my @volumes = SDM::Disk::Volume->get( filername => $self->name );

    # Before we remove the Filer, we must remove its hostmappings
    foreach my $hm ( $self->hostmappings ) {
        $self->warning_message("Remove Filer-Host mapping " . $hm->id . " for Filer " . $self->name);
        $hm->delete() or
            die "Failed to remove Filer-Host map for Filer: " . $self->name;
    }

    $self->warning_message("Remove Filer " . $self->name);
    my $res = $self->SUPER::delete();

    # After we remove a filer, we iterate through Volumes that claimed to have been mounted
    # on this filer and see if they're now orphans.
    foreach my $volume (@volumes) {
        if ($volume->is_orphan()) {
            # FIXME: can't use warning_message here or we silently abort
            $self->warning_message("Removing now orphaned Volume: " . $volume->mount_path);
            $volume->delete();
        }
    }

    return $res;
}

1;
