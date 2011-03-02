package System::Disk::Volume;

use strict;
use warnings;

use Date::Manip;
use System;
class System::Disk::Volume {
    table_name => 'DISK_VOLUME',
    id_by => [
        volume_id => { is => 'Integer' },
    ],
    has => [
        filer         => { is => 'System::Disk::Filer', id_by => 'filername', constraint_name => 'VOLUME_FILER_FK' },
        mount_path    => { is => 'Text', len => 255 },
        physical_path => { is => 'Text', len => 255 },
        total_kb      => { is => 'UnsignedInteger' },
        used_kb       => { is => 'UnsignedInteger' },
        status        => { via => 'filer' },
    ],
    has_optional => [
        # FIXME: How do we link with DISK_ASSIGNMENT here?
        #disk_group    => { is => 'System::Disk::Assignment', id_by => {'group_name','volume_id'}},
        created       => { is => 'DATE' },
        last_modified => { is => 'DATE' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

sub is_current {
  my $self = shift;

  return 0 if (! defined $self->last_modified);

  return 0 if ($self->last_modified eq "0000-00-00 00:00:00");

  my $date0 = ParseDate($self->last_modified);
  return 0 if (! defined $date0);

  my $err;
  my $date1 = ParseDate(scalar gmtime());
  my $calc = DateCalc($date0,$date1,\$err);

  die "Error in DateCalc: $date0, $date1, $err\n" if ($err);
  die "Error in DateCalc: $date0, $date1, $err\n" if (! defined $calc);

  my $delta = Delta_Format($calc,0,'%st');
  return 0 if (! defined $delta);

  # FIXME: define host_maxage someplace, but not as a db column.
  return 1
    if $delta < $self->{host_maxage};

  return 0;
}

sub validate_volumes {
  # FIXME: Add code to validate volumes
  # similar to DiskUsage::Cache
  my $self = shift;
  return 0;
}

sub purge {
  # FIXME: Add code to remove stale volumes
  # similar to DiskUsage::Cache
  my $self = shift;
  return 0;
}

__END__

sub unusable_volume_percent { return .05 }
sub maximum_reserve_size { return 1_073_741_824 } # 1 TB

sub most_recent_allocation {
    my $self = shift;
    # Unless otherwise specified, the objects returned by this get will be sorted by increasing
    # id value. This is ONLY true if the id is numeric and single-column. If any fields other than
    # allocator id are ever added to the id_by property of allocations, this get will need to be modified
    my @allocations = System::Disk::Allocation->get(mount_path => $self->mount_path);
    return unless @allocations;
    return $allocations[-1];
}

1;
