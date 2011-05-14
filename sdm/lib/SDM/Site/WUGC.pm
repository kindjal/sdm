
package SDM::Site::WUGC;
use strict;
use warnings;

# ensure nothing loads the old SDM::Config module
BEGIN { $INC{"SDM/Config.pm"} = 'no' };

# Default production DB settings
$ENV{SYSTEM_DEPLOYMENT} ||= 'production';
$ENV{SYSTEM_GENOME_INSTITUTE_NETWORKS} = 1;

if ($ENV{SYSTEM_DEPLOYMENT} eq 'testing') {
    $ENV{SYSTEM_DATABASE_DRIVER} ||= 'SQLite';
    $ENV{SYSTEM_DATABASE_HOSTNAME} ||= 'localhost';
} elsif ($ENV{SYSTEM_DEPLOYMENT} eq 'production') {
    $ENV{SYSTEM_DATABASE_DRIVER} ||= 'Pg';
    #$ENV{SYSTEM_DATABASE_HOSTNAME} ||= 'sysmgr.gsc.wustl.edu';
    $ENV{SYSTEM_DATABASE_HOSTNAME} ||= 'localhost';
}

1;

=pod

=head1 NAME

SDM::Site::WUGC - internal configuration for the WU Genome Institute.

=head1 DESCRIPTION

Configures the SDM suite to work on the internal network at
The Genome Institute at Washington University

=head1 BUGS

For defects with any software in the genome namespace,
contact sdm-dev@genome.wustl.edu.

=cut



