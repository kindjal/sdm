
package System::Disk::Filer::Command::Usage;

use strict;
use warnings;

use System;
use Smart::Comments;

# Checking currentness in host_is_current()
use Date::Manip;
use Date::Manip::Date;
# Usage function
use Pod::Find qw(pod_where);
use Pod::Usage;
use Log::Log4perl qw(:easy);

use File::Basename qw(basename);
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
      doc => 'Not yet implemented',
    },
    timeout => {
      is => 'Number',
      default => 15,
      doc => 'Not yet implemented',
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
      doc => 'Path to rrd file storage (not yet implemented)',
    },
    purge => {
      is => 'Boolean',
      default => 0,
      doc => 'Purge aged volume entries (not yet implemented)',
    },
    cleanonly => {
      is => 'Boolean',
      default => 0,
      doc => 'Remove volumes from the DB that the Filer no longer exports',
    },
    is_current => {
      is => 'Boolean',
      default => 0,
      doc => 'Check currency status',
    },
    filer => {
      is => 'System::Disk::Filer',
      id_by => 'name',
      doc => 'SNMP query the named filer',
    }
  ],
  doc => 'Queries volume usage via SNMP',
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
    ### update_volume for filer: $filer

    unless ($filer) {
        $self->error_message("No filer given");
        return;
    }

    ### First find and remove volumes in the DB that are not detected on this filer
    # Now, for this filer, find any stored volumes that aren't present
    # in the volumedata retrieved via SNMP.
    foreach my $volume ( System::Disk::Volume->get( filername => $filer->name ) ) {
        my $path = $volume->mount_path;
        $path =~ s/\//\\\//g;
        # FIXME: do we want to auto-remove like this?
        if ( ! grep /$path/, keys %$volumedata ) {
            $volume->delete;
        }
    }
    return if ($self->cleanonly);

    foreach my $physical_path (keys %$volumedata) {
        ### update physical_path: $physical_path
        # FIXME: How can we know the mount path aside from convention?
        my $mount_path = '/gscmnt/' . basename $physical_path;
        my $params = { filername => $filer->name, physical_path => $physical_path, mount_path => $mount_path };
        my $volume = System::Disk::Volume->get_or_create( $params );
        ### params: $params
        ### volume returned: $volume
        unless ($volume) {
            $self->error_message("Failed to get_or_create volume: " . Data::Dumper::Dumper $params);
            return;
        }
        ### volume: $volume
        ### volumedata: $volumedata

        foreach my $attr (keys %{ $volumedata->{$physical_path} }) {
           # FIXME: Don't update disk group from filesystem, only the reverse.
           #next if ($attr eq 'disk_group');
           my $p = $volume->__meta__->property($attr);
           # Primary keys are immutable, don't try to update them
           ### update volume attr: $attr
           ### p: $p
           $volume->$attr($volumedata->{$physical_path}->{$attr})
             if (! $p->is_id and $p->is_mutable);
           $volume->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
        }
    }
}

sub fetch_aging_volumes {
    my $self = shift;
    ### fetch_aging_volumes
    $self->error_message("max age has not been specified\n")
        if (! defined $self->vol_maxage);
    $self->error_message("max age makes no sense: $self->vol_maxage\n")
        if ($self->vol_maxage < 0 or $self->vol_maxage !~ /\d+/);
    my $date = Date::Manip::Date->new();
    $date->parse($self->vol_maxage . " days ago");
    #return System::Disk::Volume->get( { "last_modified <" => $date->printf("%Y-%m-%d %H:%M:%S") } );
    my $sql = "SELECT physical_path, filername FROM disk_volume WHERE last_modified < date(\"now\",\"-" . $self->vol_maxage . " days\") ORDER BY last_modified";
    return System::Disk::Volume->get( sql => $sql );
}

sub validate_volumes {
    ### validate_volumes
    # See if we have volumes that haven't been updated since maxage.
    my $self = shift;
    foreach my $volume ($self->fetch_aging_volumes()) {
        $self->warning_message("Aging volume: $volume->filername $volume->mount_path\n");
    }
}

sub purge_volumes {
    # FIXME: implement
    ### purge_volumes
    my $self = shift;
    foreach my $volume ($self->fetch_aging_volumes()) {
        $volume->delete();
    }
}

sub execute {
    ### execute Usage
    my $self = shift;

    my @filers;
    if (defined $self->filer) {
        push @filers, $self->filer;
    } else {
        @filers = System::Disk::Filer->get( status => 1 );
    }

    foreach my $filer (@filers) {
        ### filer: $filer
        # Just check is_current
        if ($self->is_current) {
            if ($filer->is_current($self->host_maxage)) {
                $self->warning_message("Filer $filer is current");
            } else {
                $self->warning_message("Filer $filer is NOT current, last check: " . $filer->last_modified);
            }
            next;
        }

        # Update any filers that are not current
        my $result = {};
        eval {
            my $snmp = System::Utility::SNMP->create();
            $result = $snmp->query_snmp($filer->name);
        };
        if ($@) {
            # log here, but not high priority, it's common
            $self->warning_message("Error with SNMP query: $@");
            next;
        }

        if (! scalar keys %$result) {
            $self->warning_message("Filer returned empty SNMP result: " . $filer->name);
        } else {
            $self->update_volume( $filer, $result );
        }
    }
    ### execute Usage complete
}

1;
