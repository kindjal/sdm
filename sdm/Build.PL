#! /usr/bin/perl

use Module::Build;

my $build = Module::Build->new(
  module_name => 'SDM',
  license => 'lgpl',
  dist_version => '0.12',
  dist_abstract => 'Modules for system data miner',
  scripts => [ 'bin/sdm' ],
  build_requires => {
    'Module::Build' => '',
    'UR' => '0.31',
  },
  requires => {
    'UR' => '0.31',
  },
);

$build->add_build_element('sqlite3-schema');
$build->create_build_script;
