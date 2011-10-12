
package SDM::Utility::DiskGroupRRD;

use strict;
use warnings;
use DBI;
use RRDTool::OO;
use File::Path;
use Time::Local;
use Log::Log4perl qw/:levels/;

class SDM::Utility::DiskGroupRRD {
    is => "SDM::Command::Base",
    has => [
        rrdpath => {
            is => 'Text',
            doc => 'location of stored rrd files',
            default_value => $ENV{SDM_DISK_RRDPATH},
        }
    ]
};

sub prep_fake_rrd {
  my $self = shift;
  my $rrd = shift;
  $self->{logger}->debug(__PACKAGE__ . " prep_fake_rrd\n");

  my $total = 0;
  my $used  = 0;

  my $date = 1234245600;
  my $end  = 1297404000; # Arbitrary date bounds

  $self->create_rrd($rrd,$date) or
    $self->error_message("failed during create rrd: $@\n");

  until ($date > $end) {
    $date = $date + 86400;
    $total += 1000000000;
    $used += 900000000;
    $rrd->update( time => $date, values => { total => $total, used => $used } );
  }
}

sub create_rrd {
  my $self = shift;
  my $rrd = shift;
  my $start = shift;
  $self->{logger}->debug(__PACKAGE__ . "create_rrd\n");

  if (! defined $start) {
    # beginning of today
    $start = timelocal(0,0,0,(localtime(time))[3,4,5]);
  }

  $rrd->create(

      step        => 86400,
      start       => $start,

      data_source => {
        name      => "total",
        type      => "GAUGE",
      },
      data_source => {
        name      => "used",
        type      => "GAUGE",
      },

      archive     => {
        rows      => 10,
      },
      archive     => {
        rows      => 60,
      },
      archive     => {
        rows      => 180,
      },
      archive     => {
        rows      => 360,
      },
      archive     => {
        rows      => 1800,
      },
  );
}

sub create_or_update {
    my ($self,$group,$total,$used) = @_;
    return unless (defined $group and defined $total and defined $used);
    my $rrdpath = $self->rrdpath;
    die "RRD path is unset" if (! defined $rrdpath);
    if (! -d $rrdpath) {
        File::Path::mkpath $rrdpath or die "Failed to create directory '$rrdpath': $!";
        $self->logger->warn(__PACKAGE__ . " created directory '$rrdpath'");
    }
    my $rrdfile = $rrdpath . "/" . lc($group) . ".rrd";

    $self->logger->info(__PACKAGE__ . " create_or_update($rrdfile,$group,$total,$used)");

    unless (-w $rrdpath) {
        $self->logger->warn(__PACKAGE__ . " no write permission for '$rrdpath', skipping rrd update");
        return;
    }

    my $rrd = RRDTool::OO->new(
        file => $rrdfile,
    );

    if (! -s $rrdfile ) {
        $self->create_rrd($rrd);
    }

    $rrd->update( values => { total => $total, used => $used } );
    return $rrdfile;
}

sub run {
    my $self = shift;
    $self->logger->debug(__PACKAGE__ . " run");
    my $set = SDM::Disk::Volume->define_set();
    my $view = $set->create_view( perspective => 'group', toolkit => 'json' );

    foreach my $item ( $view->aaData ) {
        $self->create_or_update($item->[0],$item->[1],$item->[2]);
    }
}

1;
