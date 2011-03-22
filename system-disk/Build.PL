#! /usr/bin/perl

use Module::Build;

my $build = Module::Build->new(
  module_name => 'System',
  license => 'lgpl',
  dist_version => '0.01',
  dist_abstract => 'Modules for system management',
  scripts => [ 'bin/system' ],
  build_requires => {
    'Module::Build' => '',
    'UR' => '0.29',
    'System' => '',
  },
  requires => {
    'UR' => '0.29',
    'System' => '',
  },
);

$build->create_build_script;
