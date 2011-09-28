
use strict;
use warnings;

BEGIN {
    $ENV{SDM_DEPLOYMENT} ||= "testing";
};

use SDM;
use SDM::Utility::GPFS::DiskUsage;

use Test::More;
use Test::Output;
use Test::Exception;

unless ($ENV{SDM_GENOME_INSTITUTE_NETWORKS}) {
    plan skip_all => "Test only valid on GI networks";
}

# Start with a fresh database
use File::Basename qw/dirname/;
my $top = dirname $FindBin::Bin;
require "$top/t/sdm-disk-lib.pm";
ok( SDM::Test::Lib->testinit == 0, "ok: init db");

# This test requires a real network connection to a lives host.
my $host = 'linuscs107';

my @params = ( loglevel => 'DEBUG', hostname => $host );

sub fileslurp {
    my $filename = shift;
    return unless (defined $filename);
    open FH, "<", $filename or die "failed to open $filename: $!";
    my $content = do { local $/; <FH> };
    close(FH);
    return $content;
}

my $c = SDM::Utility::GPFS::DiskUsage->create( @params );

$c->parse_mmlscluster( fileslurp( "$top/t/mmlscluster.txt" ) );
my $h = SDM::Disk::Host->get( hostname => "linuscs103" );
ok( $h->master == 1, "master host found" );

my $vol = $c->parse_mmlsnsd( fileslurp( "$top/t/mmlsnsd.txt" ) );
$c->parse_nsd_df( fileslurp( "$top/t/df.txt" ), $vol );
$c->parse_disk_groups( fileslurp( "$top/t/disk_groups.txt" ), $vol );
my $expected = {
    'ams2k4lun00b4' => [
        'linuscs105.gsc.wustl.edu',
        'linuscs106.gsc.wustl.edu',
        'linuscs103.gsc.wustl.edu',
        'linuscs104.gsc.wustl.edu '
        ],
    'mount_path' => '/gscmnt/gc4013',
    'physical_path' => '/vol/gc4013',
    'disk_group' => 'INFO_GENOME_MODELS',
    'total_kb' => '6914310144',
    'ams2k4lun00b3' => [
        'linuscs103.gsc.wustl.edu',
        'linuscs104.gsc.wustl.edu',
        'linuscs105.gsc.wustl.edu',
        'linuscs106.gsc.wustl.edu '
        ],
    'used_kb' => '5184528384',
    'ams2k4lun002f' => [
        'linuscs103.gsc.wustl.edu',
        'linuscs104.gsc.wustl.edu',
        'linuscs105.gsc.wustl.edu',
        'linuscs106.gsc.wustl.edu '
        ]
};
ok( is_deeply( $vol->{'gc4013'}, $expected, "ok: is_deeply"), "ok: mmlsnsd parses");

$c->parse_mmrepquota( fileslurp( "$top/t/mmrepquota.txt" ), $vol );
my %fs1 = (
        name => 'gc7000',
        type => 'FILESET',
        kb_size => '62210072304',
        kb_quota => '0',
        kb_limit => '214748364800',
        kb_in_doubt => '27967088',
        kb_grace => 'none',
        files => '214324',
        file_quota => '0',
        file_limit => '0',
        file_in_doubt => '138',
        file_grace => 'none',
        file_entryType => 'e',
        parent_volume_name => 'aggr0'
);
my %fs2 = (
        name => 'gc7001',
        type => 'FILESET',
        kb_size => '93793940608',
        kb_quota => '0',
        kb_limit => '214748364800',
        kb_in_doubt => '3597672',
        kb_grace => 'none',
        files => '4376582',
        file_quota => '0',
        file_limit => '0',
        file_in_doubt => '574',
        file_grace => 'none',
        file_entryType => 'e',
        parent_volume_name => 'aggr0'
);
$expected = [
  \%fs1,
  \%fs2,
];
ok( is_deeply( $vol->{'aggr0'}->{'filesets'}, $expected, "ok: is_deeply"), "ok: mmreqpquota parses");

done_testing();
