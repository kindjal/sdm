package System::Disk::Array;

use strict;
use warnings;

use System;
class System::Disk::Array {
    type_name => 'disk array',
    table_name => 'DISK_ARRAY',
    id_by => [
        array_id => { is => 'INTEGER' },
    ],
    has => [
        host_id            => {
            is => 'Integer',
            calculate_from   => ['host'],
            calculate        => sub {
                                  my $host = @_;
                                  return unless $host;
                                  my $h = System::Disk::Host->get( hostname => $host );
                                  return $h->id;
                                },
        },
        model              => { is => 'VARCHAR(255)' },
        size               => { is => 'UNSIGNED INTEGER' },
        type               => { is => 'VARCHAR(255)' },
    ],
    has_optional => [
        created            => { is => 'DATE' },
        last_modified      => { is => 'DATE' },
    ],
    has_param => [
        host               => { is => 'Text' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

1;
