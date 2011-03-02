package System::Disk::Filer;

use strict;
use warnings;

use System;
use Date::Manip;

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
        hosts  => { is => 'System::Disk::Host', reverse_as => 'filer' },
        arrays => { is => 'System::Disk::Array', via => 'hosts', to => 'arrays' },
    ],
    schema_name => 'Disk',
    data_source => 'System::DataSource::Disk',
};

sub is_current {
  my $self = shift;
  my $host_maxage = shift;

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

  print "is_current: delta $delta\n";

  return 0 if (! defined $delta);

  return 1
    if $delta < $host_maxage;

  return 0;
}

1;
