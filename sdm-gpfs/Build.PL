#! /usr/bin/perl

use Module::Build;

# With git repos, this should work.
BEGIN {
    push @INC, "../sdm/lib";
};

my $build = Module::Build->new(
  module_name => 'SDM',
  license => 'lgpl',
  dist_version => '0.12',
  dist_abstract => 'Modules for GPFS querying',
  build_requires => {
    'Module::Build' => '',
    'UR' => '0.31',
    'SDM' => '',
  },
  requires => {
    'UR' => '0.31',
    'SDM' => '',
  },
);

$build->add_build_element('schema');
$build->create_build_script;
