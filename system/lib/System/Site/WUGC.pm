
package System::Site::WUGC;
use strict;
use warnings;

# ensure nothing loads the old System::Config module
BEGIN { $INC{"System/Config.pm"} = 'no' };

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

System::Site::WUGC - internal configuration for the WU Institute of Genomic Medicine 

=head1 DESCRIPTION 

Configures the System Modeling system to work on the internal network at 
The Institute of Genomic Medicine at Washington University

This module ensures that GSCApp and related modules are avialable to the running application.

It is currently a goal that GSCApp need not be used by this module, and that individual
modules under it provide transparent wrappers for WUIGM-specific infrastructure.

=head1 BUGS

For defects with any software in the genome namespace,
contact system-dev@genome.wustl.edu.

=cut



