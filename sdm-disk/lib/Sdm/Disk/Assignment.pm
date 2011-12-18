package Sdm::Disk::Assignment;

use strict;
use warnings;
use Sdm;

class Sdm::Disk::Assignment {
    table_name => 'disk_volume_group',
    id_by => [
        group           => { is => 'Sdm::Disk::Group', id_by => 'group_name' },
        volume          => { is => 'Sdm::Disk::Volume', id_by => 'volume_id' },
    ],
    has => [
        name            => { via => 'group' },
    # FIXME: what are we doing with users?
    #    #user_name       => { via => 'group' },
        subdirectory    => { via => 'group' },
        mount_path      => { via => 'volume' },
        total_kb        => { via => 'volume' },
        filername       => { via => 'volume' },
    # FIXME: should allocation be part of volume? Or a DISK_ALLOCATION new table?
    #    unallocated_kb  => { via => 'volume' },
        percent_full    => {
                calculate_from => 'absolute_path',
                calculate => q(
                  my @pct_full = `df -h $absolute_path`;
                  my @split_pct_full = split(/%/,$pct_full[-1]);
                  @split_pct_full = split (/ /,$split_pct_full[0]);
                  return $split_pct_full[-1];
                ) },
        absolute_path   => {
                calculate_from => [ 'mount_path', 'subdirectory' ],
                calculate => q(
                  return join('/', grep { ! /^$/ } ( $mount_path,$subdirectory ) );
                ) },
    ],
    schema_name => 'Disk',
    data_source => 'Sdm::DataSource::Disk',
};

1;

