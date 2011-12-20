
package Sdm::Disk::Filer;

use strict;
use warnings;

use Sdm;
use Date::Manip;
use feature 'switch';

class Sdm::Disk::Filer {
    table_name => 'disk_filer',
    id_by => [
        name            => { is => 'Text' },
    ],
    has_optional => [
        type            => {
            is => 'Text',
            doc => 'The type of filer determines the means of querying for usage info',
            valid_values => ['gpfs','snmp'],
            default_value => 'gpfs'
        },
        duplicates      => {
            is => 'Text',
            doc => 'Indicates if a filer duplicates another, eg. a polyserve node.  Enter a filer name here.',
        },
        comments        => { is => 'Text' },
        filesystem      => { is => 'Text' },
        created         => { is => 'DATE' },
        last_modified   => { is => 'DATE' },
        status          => { is => 'UnsignedInteger', default => 0 },
        master          => {
            is => 'Text',
            calculate => q| return $self->name if ($self->type eq 'snmp'); foreach my $h ($self->host) { return $h->hostname if ($h->master); }; |,
        },
    ],
    has_many_optional => [
        hostmappings    => { is => 'Sdm::Disk::FilerHostBridge', reverse_as => 'filer' },
        host            => { is => 'Sdm::Disk::Host', via => 'hostmappings', to => 'host'  },
        hostname        => { is => 'Text', via => 'host', to => 'hostname' },
        volumemappings  => { is => 'Sdm::Disk::VolumeFilerBridge', reverse_as => 'filer' },
        volume          => { is => 'Sdm::Disk::Volume', via => 'volumemappings', to => 'volume' },
        # The obvious way to reference arraynames produces a list with duplicates
        #arrayname       => { via => 'host', to => 'arrayname' },
        # Use this calculation to produce a list of unique arraynames
        arrayname      => {
            is => 'Text',
            calculate => q/ my %h; foreach my $h ($self->host) { map { $h{$_} = 1 } $h->arrayname }; return keys %h; /
        },
    ],
    schema_name => 'Disk',
    data_source => 'Sdm::DataSource::Disk',
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

sub get_volume {
    my $self = shift;
    my (%params) = @_;
    my @volumes = Sdm::Disk::Volume->get();
    return @volumes;
}

=head2 create_volume
Create method for Volumes assigned to this Filer.
=cut
sub create_volume {
    my $self = shift;
    my (%params) = @_;
    my $volume;
    $params{filername} = $self->name;
    $volume = Sdm::Disk::Volume->create( %params );
    unless ($volume) {
        $self->error_message("failed to create volume");
        return;
    }
    return $volume;
}

=head create
Create method for Filer sets created attribute.
=cut
sub create {
    my $self = shift;
    my $bx = $self->define_boolexpr(@_);

    my @missing;
    foreach my $attr ( $self->__meta__->properties ) {
        next if ($attr->is_optional or $attr->via or $attr->is_calculated or $attr->is_id or $attr->id_by or defined $attr->default_value);
        push @missing, $attr->property_name unless ($bx->value_for($attr->property_name));
    }
    push @missing,"name" unless ($bx->value_for('name'));
    if (@missing) {
        $self->error_message("missing required attributes in create(): " . join(" ",@missing));
        return;
    }

    my $filer = $self->SUPER::create( $bx );
    $filer->created( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
    return $filer;
}

sub duplicates {
    # If we set this filer as a duplicate, then we must remove all its volumes
    # since this means they are duplicates of some other filer and we don't
    # want to double count them.
    my $self = shift;
    unless (@_) {
        return $self->__duplicates;
    }

    my @volume_ids;
    foreach my $vm ( $self->volumemappings ) {
        $self->warning_message("Remove Volume-Filer mapping " . $vm->id . " for Filer " . $self->name);
        push @volume_ids, $vm->volume_id;
        $vm->delete() or
            die "Failed to remove Volume-Filer map for Filer: " . $self->name;
    }

    # After we remove a filer, we iterate through Volumes that claimed to have been mounted
    # on this filer and see if they're now orphans.
    foreach my $vid (@volume_ids) {
        my $volume = Sdm::Disk::Volume->get( $vid );
        if (defined $volume and $volume->is_orphan()) {
            # FIXME: can't use warning_message here or we silently abort
            $self->warning_message("Removing now orphaned Volume: " . $volume->physical_path);
            $volume->delete();
        }
    }

    return $self->__duplicates(@_);
}

sub delete {
    my $self = shift;

    # Before we remove the Filer, we must remove its hostmappings
    foreach my $hm ( $self->hostmappings ) {
        $self->warning_message("Remove Filer-Host mapping " . $hm->id . " for Filer " . $self->name);
        $hm->delete() or
            die "Failed to remove Filer-Host map for Filer: " . $self->name;
    }

    # Now the Volume mappings...
    my @volume_ids;
    foreach my $vm ( $self->volumemappings ) {
        $self->warning_message("Remove Volume-Filer mapping " . $vm->id . " for Filer " . $self->name);
        push @volume_ids, $vm->volume_id;
        $vm->delete() or
            die "Failed to remove Volume-Filer map for Filer: " . $self->name;
    }

    $self->warning_message("Remove Filer " . $self->name);
    my $res = $self->SUPER::delete();

    # After we remove a filer, we iterate through Volumes that claimed to have been mounted
    # on this filer and see if they're now orphans.
    foreach my $vid (@volume_ids) {
        my $volume = Sdm::Disk::Volume->get( $vid );
        if ($volume->is_orphan()) {
            $volume->warning_message("Removing now orphaned Volume: $vid");
            $volume->delete();
        }
    }
    return $res;
}

1;
