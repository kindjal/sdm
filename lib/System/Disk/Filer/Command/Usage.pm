
package System::Disk::Filer::Command::Usage;

use strict;
use warnings;

use System;

# Checking currentness in host_is_current()
use Date::Manip;
use Date::Manip::Date;
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

sub update_volume {
    my $self = shift;
    my $filer = shift;
    my $volumedata = shift;

    $self->{logger}->debug("Store result");
    foreach my $physical_path (keys %$volumedata) {
        my $volume = System::Disk::Volume->get_or_create( filer => $filer, physical_path => $physical_path );
        foreach my $attr (keys %{ $volumedata->{$physical_path} }) {
           # Don't update disk group from filesystem, only the reverse.
           next if ($attr eq 'disk_group');
           my $p = $volume->__meta__->property($attr);
           # Primary keys are immutable, don't try to update them
           $volume->$attr($volumedata->{$physical_path}->{$attr})
             if (! $p->is_id);
        }
    }
    # Now, for this filer, find any stored volumes that aren't present
    # in the volumedata retrieved via SNMP.
    my @volumes = System::Disk::Volume->get( filer => $filer );
    foreach my $volume ( @volumes ) {
        my $path = $volume->physical_path;
        $self->{logger}->warn("Volume $path");
        $path =~ s/\//\\\//g;
        # FIXME: do we want to remove like this?
        if ( ! grep /$path/, keys %$volumedata ) {
            $self->{logger}->warn("Volume " . $volume->physical_path . " no longer appears on filer " . $filer->name . "\n");
            $volume->delete();
        }
    }
}

sub fetch_aging_volumes {
    my $self = shift;
    $self->{logger}->debug("fetch_aging_volumes()\n");
    $self->error("max age has not been specified\n")
        if (! defined $self->vol_maxage);
    $self->error("max age makes no sense: $self->vol_maxage\n")
        if ($self->vol_maxage < 0 or $self->vol_maxage !~ /\d+/);
    my $date = Date::Manip::Date->new();
    $date->parse($self->vol_maxage . " days ago");
    #return System::Disk::Volume->get( { "last_modified <" => $date->printf("%Y-%m-%d %H:%M:%S") } );
    my $sql = "SELECT physical_path, filername FROM disk_volume WHERE last_modified < date(\"now\",\"-" . $self->vol_maxage . " days\") ORDER BY last_modified";
    $self->{logger}->debug("sql $sql\n");
    return System::Disk::Volume->get( sql => $sql );
}

sub validate_volumes {
    # See if we have volumes that haven't been updated since maxage.
    my $self = shift;
    $self->{logger}->debug("validate_volumes()\n");
    foreach my $volume ($self->fetch_aging_volumes()) {
        $self->{logger}->warn("Aging volume: $volume->filername $volume->mount_path\n");
    }
}

sub purge_volumes {
    my $self = shift;
    $self->{logger}->debug("purge_volumes()\n");
    foreach my $volume ($self->fetch_aging_volumes()) {
        $volume->delete();
    }
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

    $self->{logger}->debug("filer: " . $self->filer->name);

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
                next;
            }

            if (! scalar keys %$result) {
                $self->{logger}->info("Filer " . $filer->name . "has no exported volumes\n");
            } else {
                $self->{logger}->info("Updating filer " . $filer->name . "\n");
                $self->update_volume( $filer, $result );
            }
        } else {
            $self->{logger}->info("filer " . $filer->name . "is current\n");
        }
    }
}

1;
