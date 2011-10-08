
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
    $ENV{UR_DBI_NO_COMMIT} = 0;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 0;
};

use SDM;

use Test::More;
use Test::Output;
use Test::Exception;

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname __FILE__;
require "$top/sdm-disk-lib.pm";
my $t = SDM::Disk::Lib->new();
my $perl = $t->{perl};
my $sdm = $t->{sdm};
ok( $t->testinit == 0, "ok: init db");

stderr_unlike { $t->runcmd("$perl $sdm disk group add --name SYSTEMS"); } qr|WARNING:  nonstandard use of \' in a string literal|, "APIPE-755: issue in UR/DBI.pm";

done_testing();
