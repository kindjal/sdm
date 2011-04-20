
package System::Disk::Filer::Command::Import;

use strict;
use warnings;
use System;
use YAML::XS qw/Load/;
use File::Slurp qw/read_file/;

class System::Disk::Filer::Command::Import {
    is => 'System::Command::Base',
    doc => 'Import filer data from YAML file',
    has => [
        yaml => { is => 'Text', doc => 'YAML file name' },
    ],
};

sub help_brief {
    return 'Import filer data from a YAML file';
}

sub help_synopsis {
    return <<EOS;
Import filer data from a YAML file
EOS
}

sub help_detail {
    return <<EOS;
Import filer data from a YAML file
EOS
}

sub execute {
    my $self = shift;
    my $configfile = $self->yaml;

    unless (-f $configfile) {
        $self->error_message("please specify a valid yaml file path: $!");
        return;
    }

    my $config = Load scalar read_file($configfile) or
        die "error loading config file '$configfile': $!";
    $self->{logger}->debug("loaded $configfile");

    foreach my $filername (keys %$config) {
        # Create all hosts and arrays for each filer in the YAML
        foreach my $hostname (split(/\s+/,$config->{$filername}->{hosts})) {
            $self->{logger}->debug("add host $hostname");
            my $host = System::Disk::Host->get_or_create( hostname => $hostname );
            unless ($host) {
                $self->error_message("the host named '$hostname' related to filer '$filername' does not exist in the DB and cannot be added: $!");
                return;
            }
        }
        foreach my $arrayname (split(/\s+/,$config->{$filername}->{arrays})) {
            $self->{logger}->debug("add array $arrayname");
            my $array = System::Disk::Array->get_or_create( name => $arrayname );
            unless ($array) {
                $self->error_message("the array named '$arrayname' related to filer '$filername' does not exist in the DB and cannot be added: $!");
                return;
            }
            foreach my $hostname (split(/\s+/,$config->{$filername}->{hosts})) {
                $self->{logger}->debug("assign array $arrayname to host $hostname");
                $array->assign( $hostname );
            }
        }
        $self->{logger}->debug("add filer $filername");
        my $filer = System::Disk::Filer->get_or_create( name => $filername, comments => $config->{$filername}->{comments} );
        unless ($filer) {
            $self->error_message("the filer named '$filername' does not exist in the DB and cannot be added: $!");
            return;
        }
        foreach my $hostname (split(/\s+/,$config->{$filername}->{hosts})) {
            $self->{logger}->debug("assign host $hostname to filer $filername");
            my $host = System::Disk::Host->get( hostname => $hostname );
            $host->assign( $filername );
        }
    }
    return 1;
}

1;
