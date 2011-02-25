package System::Disk::Volume::Command::List;

use strict;
use warnings;

use System;

class System::Disk::Volume::Command::List {
    is => 'UR::Object::Command::List',
    has => [
        subject_class_name  => {
            is_constant => 1,
            value => 'System::Disk::Volume',
        },
        show => {
            # FIXME: add filer hostname when we can
            default_value => 'physical_path,mount_path,total_kb,used_kb'
        },
    ],
};

1;
