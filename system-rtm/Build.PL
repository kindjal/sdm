#! /usr/bin/perl

use Module::Build;

# With git repos, this should work.
BEGIN {
    push @INC, "../system/lib";
};

# On a packaging system, we Build-Require ur-system-namespace, so this should work.
use System;

my $build = Module::Build->new(
  module_name => 'System',
  license => 'lgpl',
  dist_version => '0.01',
  dist_abstract => 'Modules for disk management',
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
