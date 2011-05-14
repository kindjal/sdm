package SDM::Env::SDM_GENOME_INSTITUTE_NETWORKS;

$ENV{SDM_GENOME_INSTITUTE_NETWORKS} ||= 0;

=head2
SDM::Env::SDM_GENOME_INSTITUTE_NETWORKS

This environment variable indicates that we're running on GI networks, and can
make some assumptions about network layouts.  This turns on some features and tests.

This environment variable is set in Site/WUGC.pm.
=cut

1;
