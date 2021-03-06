#! /usr/bin/perl

use Module::Build;

# With git repos, this should work.
BEGIN {
    push @INC, "../sdm/lib";
};

my $build = Module::Build->new(
  module_name => 'Sdm',
  license => 'lgpl',
  dist_version => '0.17',
  dist_abstract => 'Sdm Asset',
  build_requires => {
    'Module::Build' => '',
    'UR' => '0.31',
    'Sdm' => '',
  },
  requires => {
    'UR' => '0.31',
    'Sdm' => '',
  },
);

$build->add_build_element('schema');
$build->create_build_script;
