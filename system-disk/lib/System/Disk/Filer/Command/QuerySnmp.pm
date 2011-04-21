
package System::Disk::Filer::Command::QuerySnmp;

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

use File::Basename qw(basename);
use System::Utility::SNMP;

# Autoflush
local $| = 1;

use Smart::Comments -ENV;

class System::Disk::Filer::Command::QuerySnmp {
  is => 'System::Command::Base',
  has_optional => [
    force => {
      is => 'Boolean',
      default => 0,
      doc => 'Query all filers regardless of status',
    },
    allow_mount => {
      is => 'Boolean',
      default => 0,
      doc => 'Allow mounting of filesystems to discover disk groups',
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
    discover_groups => {
      is => 'Boolean',
      default => 0,
      doc => 'Discover disk groups from touch files on volumes and create them on the fly',
    },
    is_current => {
      is => 'Boolean',
      default => 0,
      doc => 'Check currency status',
    },
    filer => {
      # If I use is => Filer here, UR errors out immediately if the filer doesn't exist.
      # If I use is => Text, then I can use get_or_create to add on the fly, or query them all.
      #is => 'System::Disk::Filer',
      is => 'Text',
      doc => 'SNMP query the named filer',
    },
    physical_path => {
      is => 'Text',
      doc => 'SNMP query the named filer for this export',
    },
    query_paths => {
      is => 'Boolean',
      doc => 'SNMP query the named filer for exports, but not usage',
    },
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

=head2 update_volume
Update SNMP data for all Volumes associated with this Filer.
=cut
sub update_volume {
    my $self = shift;
    my $filer = shift;
    my $volumedata = shift;
    ### QuerySnmp update_volume for filer: $filer

    unless ($filer) {
        $self->error_message("No filer given");
        return;
    }

    $self->warning_message("Update filer " . $filer->name);

    unless ($self->physical_path) {
        ### QuerySnmp First find and remove volumes in the DB that are not detected on this filer
        # For this filer, find any stored volumes that aren't present in the volumedata retrieved via SNMP.
        # Note that we skip this step if we specified a single physical_path to update.
        foreach my $volume ( System::Disk::Volume->get( filername => $filer->name ) ) {
            foreach my $path ($volume->physical_path) {
                next unless($path);
                $path =~ s/\//\\\//g;
                # FIXME: do we want to auto-remove like this?
                if ( ! grep /$path/, keys %$volumedata ) {
                    foreach my $m (System::Disk::Mount->get( $volume->id )) {
                        ### QuerySnmp delete mount: $m
                        $m->delete;
                    }
                    ### QuerySnmp delete volume: $volume
                    $volume->delete;
                    $filer->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
                }
            }
        }
        return 1 if ($self->cleanonly);
    }

    foreach my $physical_path (keys %$volumedata) {
        ### QuerySnmp update physical_path: $physical_path
        # FIXME: How can we know the mount path aside from convention?
        my $mount_path = '/gscmnt/' . basename $physical_path;
        my $volume = System::Disk::Volume->get_or_create( filername => $filer->name, physical_path => $physical_path, mount_path => $mount_path );

        # Ensure we have the Group before we update this attribute of a Volume
        my $group_name = $volumedata->{$physical_path}->{disk_group};
        if ($group_name) {
            my $group;
            if ($self->discover_groups) {
                $group = System::Disk::Group->get_or_create( name => $volumedata->{$physical_path}->{disk_group} );
            } else {
                $group = System::Disk::Group->get( name => $volumedata->{$physical_path}->{disk_group} );
            }
            unless ($group) {
                $self->error_message("Failed to identify disk group: $group_name");
                return;
            }
            ### QuerySnmp get_or_create group returned: $group
        } else {
            $self->warning_message("No group found for $mount_path");
        }

        ### QuerySnmp volume returned: $volume
        unless ($volume) {
            $self->error_message("Failed to get_or_create volume");
            return;
        }
        ### QuerySnmp volume: $volume
        ### QuerySnmp volumedata: $volumedata

        foreach my $attr (keys %{ $volumedata->{$physical_path} }) {
           # FIXME: Don't update disk group from filesystem, only the reverse.
           #next if ($attr eq 'disk_group');
           my $p = $volume->__meta__->property($attr);
           # Primary keys are immutable, don't try to update them
           ### QuerySnmp update volume attr: $attr
           ### QuerySnmp p: $p
           $volume->$attr($volumedata->{$physical_path}->{$attr})
             if (! $p->is_id and $p->is_mutable);
           $volume->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
        }

    }
    $filer->last_modified( Date::Format::time2str(q|%Y-%m-%d %H:%M:%S|,time()) );
    return 1;
}

=head2 purge_volumes
Iterate over all Volumes associated with this Filer, check is_current() and warn on all stale volumes.
=cut
sub validate_volumes {
    my $self = shift;
    ### QuerySnmp->validate_volumes
    $self->error_message("max age has not been specified\n")
        if (! defined $self->vol_maxage);
    $self->error_message("max age makes no sense: $self->vol_maxage\n")
        if ($self->vol_maxage < 0 or $self->vol_maxage !~ /\d+/);

    foreach my $volume (System::Disk::Volume->get( filername => $self->name )) {
        $volume->validate($self->vol_maxage);
    }
}

=head2 purge_volumes
Iterate over all Volumes associated with this Filer, check is_current() and purge all stale volumes.
=cut
sub purge_volumes {
    my $self = shift;
    ### QuerySnmp->purge_volumes
    $self->error_message("max age has not been specified\n")
        if (! defined $self->vol_maxage);
    $self->error_message("max age makes no sense: $self->vol_maxage\n")
        if ($self->vol_maxage < 0 or $self->vol_maxage !~ /\d+/);

    foreach my $volume (System::Disk::Volume->get( filername => $self->name )) {
        $volume->purge($self->vol_maxage);
    }
}

=head2 execute
Execute QuerySnmp() queries SNMP on a named Filer and stores disk usage information.
=cut
sub execute {
    ### QuerySnmp execute Usage
    my $self = shift;

    my @filers;
    if (defined $self->filer) {
        @filers = System::Disk::Filer->get_or_create( name => $self->filer );
    } else {
        # Query all filers that have status => 1...
        if ($self->force) {
            @filers = System::Disk::Filer->get();
        } else {
            @filers = System::Disk::Filer->get( status => 1 );
        }
    }

    if (defined $self->physical_path) {
        unless ($self->filer) {
            $self->error_message("Specify a filer to query for physical_path: " . $self->physical_path);
            return;
        }
    }

    unless (scalar @filers) {
        $self->warning_message("No filers to be scanned. Consider using --force.");
    }

    foreach my $filer (@filers) {
        ### QuerySnmp foreach loop at: $filer
        # Just check is_current
        $self->warning_message("Query filer " . $filer->name);
        if ($self->is_current) {
            if ($filer->is_current($self->host_maxage)) {
                $self->warning_message("Filer " . $filer->name . " is current");
            } else {
                $self->warning_message("Filer " . $filer->name . " is NOT current, last check: " . $filer->last_modified);
            }
            next;
        }

        # Update any filers that are not current
        my $result = {};
        eval {
            my @args;
            if ($self->discover_groups) {
                push @args, [ allow_mount => $self->allow_mount ];
            }
            my $snmp = System::Utility::SNMP->create( @args );
            $result = $snmp->query_snmp( filer => $filer->name, physical_path => $self->physical_path );
            $filer->status(1);
        };
        if ($@) {
            # log here, but not high priority, it's common
            $self->warning_message("Error with SNMP query: $@");
            $filer->status(0);
            next;
        }

        if (! scalar keys %$result) {
            $self->warning_message("Filer " . $filer->name . " returned an empty SNMP result");
            if ($self->physical_path) {
                $self->error_message("Filer " . $filer->name . " does not export " . $self->physical_path);
            }
        } else {
            $self->update_volume( $filer, $result );
        }
    }
    ### QuerySnmp execute QuerySnmp complete
    return 1;
}

1;
