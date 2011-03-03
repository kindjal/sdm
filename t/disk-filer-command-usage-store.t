
use strict;
use warnings;

use above "System";

use Test::More;
use Test::Output;
use Test::Exception;

my $obj = System::Disk::Filer::Command::Usage->create();
$obj->prepare_logger();

my $filer = System::Disk::Filer->get( name => 'nfs11' );
my $result = { '/vol/sata812' => {
                        'total_kb' => 6438990688,
                        'disk_group' => 'PRODUCTION_SOLID',
                        'mount_path' => '/gscmnt/sata812',
                        'used_kb' => 5722964896,
                        'physical_path' => '/vol/sata812'
                      },
};
$obj->store($filer,$result);
#lives_ok { $obj->store($filer,$result); } "test_snmp_get_disk_group: connect ok";
#lives_ok { $group = $obj->get_disk_group($physical_path,$mount_path); } "test_snmp_get_disk_group: query ok";
#ok( $group eq "INFO_GENOME_MODELS", "test_snmp_get_disk_group: answer ok");
#$count+=3;
#done_testing($count);
