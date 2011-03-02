
package System::Disk::Filer::Command::Usage;

use strict;
use warnings;

use Data::Dumper;

use System;

# Checking currentness in host_is_current()
use Date::Manip;
# Usage function
use Pod::Find qw(pod_where);
use Pod::Usage;
use Log::Log4perl qw(:easy);

use System::Utility::RRD;
use System::Utility::SNMP;

# Autoflush
local $| = 1;

class System::Disk::Filer::Command::Usage {
  is => 'System::Command::Base',
  has_optional => [
    force => {
      is => 'Number',
      default => 0,
    },
    db_tries => {
      is => 'Number',
      default => 5,
    },
    timeout => {
      is => 'Number',
      default => 15,
    },
    host_maxage => {
      is => 'Number',
      default => 86400,
      doc => 'max seconds since last check',
    },
    vol_maxage => {
      is => 'Number',
      default => 15,
      doc => 'max days until volume is considered purgable',
    },
    rrdpath => {
      is => 'Text',
      default => "/var/www/domains/gsc.wustl.edu/diskusage/cgi-bin/rrd",
      doc => 'Path to rrd file storage',
    },
    purge => {
      is => 'Number',
      default => 0,
      doc => 'Purge aged volume entries',
    },
    is_current => {
      is => 'Boolean',
      default => 0,
      doc => 'Check currency status',
    },
    filer => {
      is => 'System::Disk::Filer',
      id_by => 'name',
    }
  ],
  doc => 'Queries volume usage via SNMP.',
};

sub help_brief {
    return 'Updates volume usage information';
}

sub help_synopsis {
    return <<EOS
Updates volume usage information
EOS
}

sub help_detail {
    return <<EOS
Updates volume usage information. Blah blah blah details blah.
EOS
}

sub execute {

  my $self = shift;

  $self->prepare_logger();
  $self->{logger}->debug("execute()\n");

  my @filers;
  if (defined $self->filer) {
    push @filers, $self->filer;
  } else {
    @filers = System::Disk::Filer->get( status => 1 );
  }

  foreach my $filer (@filers) {

    # Just check is_current
    if ($self->is_current) {
      if ($filer->is_current($self->host_maxage)) {
        $self->{logger}->info("Filer is current: " . $filer->name . "\n");
      } else {
        my $last = $filer->last_modified;
        $last = "<NULL>" if (! defined $last);
        $self->{logger}->info("Filer '" . $filer->name . "' is out of date, last updated: " . "$last\n");
      }
      next;
    }

    # Update any filers that are not current
    if (! $filer->is_current($self->host_maxage) ) {

      $self->{logger}->info("Querying filer " . $filer->name . "\n");
      my $result = {};
      eval {
        my $snmp = System::Utility::SNMP->create();
        $snmp->{logger} = $self->{logger};
        $result = $snmp->query_snmp($filer->name);
      };
      if ($@) {
        # log here, but not high priority, it's common
        $self->{logger}->info("snmp error: " . $filer->name . ": $@\n");
        return;
      }

      if (! scalar keys %$result) {
        $self->{logger}->info("Filer " . $filer->name . "has no exported volumes\n");
      } else {
        $self->{logger}->info("Updating filer " . $filer->name . "\n");
        #System::Disk::Volume->update( $result );
      }

    } else {
      $self->{logger}->info("filer " . $filer->name . "is current\n");
    }
  }

  #$self->validate_volumes();
}

1;
