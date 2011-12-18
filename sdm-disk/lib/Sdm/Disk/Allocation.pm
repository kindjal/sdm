
package Sdm::Disk::Allocation;

use strict;
use warnings;

use Sdm;

class Sdm::Disk::Allocation {
    id_generator => '-uuid',
    id_by => [
        id => {
            is => 'Text',
            doc => 'The id for the allocator event',
        },
    ],
    has => [
        disk_group_name => {
            is => 'Text',
            doc => 'The name of the disk group',
        },
        mount_path => {
            is => 'Text',
            doc => 'The mount path of the disk volume',
        },
        allocation_path => {
            is => 'Text',
            doc => 'The sub-dir of the disk volume for which space is allocated',
        },
        kilobytes_requested => {
            is => 'Number',
            doc => 'The disk space allocated in kilobytes',
        },
        owner_class_name => {
            is => 'Text',
            doc => 'The class name for the owner of this allocation',
        },
        owner_id => {
            is => 'Text',
            doc => 'The id for the owner of this allocation',
        },
        owner => {
            id_by => 'owner_id',
            is => 'UR::Object',
            id_class_by => 'owner_class_name'
        },
        group_subdirectory => {
            is => 'Text',
            doc => 'The group specific subdirectory where space is allocated',
        },
        absolute_path => {
            calculate_from => ['mount_path','group_subdirectory','allocation_path'],
            calculate => q{ return $mount_path .'/'. $group_subdirectory .'/'. $allocation_path; },
        },
        volume => { 
            is => 'Sdm::Disk::Volume',
            calculate_from => 'mount_path',
            calculate => q| return Sdm::Disk::Volume->get(mount_path => $mount_path); |
        },
    ],
    has_optional => [
        original_kilobytes_requested => {
            is => 'Number',
            doc => 'The disk space allocated in kilobytes',
        },
        kilobytes_used => {
            is => 'Number',
            default => 0,
            doc => 'The actual disk space used by owner',
        },
        creation_time => {
            is => 'DateTime',
            doc => 'Time at which the allocation was created',
        },
        reallocation_time => {
            is => 'DateTime',
            doc => 'The last time at which the allocation was reallocated',
        },
    ],
    table_name => 'GENOME_DISK_ALLOCATION',
    data_source => 'Sdm::DataSource::GMSchema',
};

1;
