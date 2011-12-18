#! /usr/bin/perl

use Module::Build;

# With git repos, this should work.
BEGIN {
    push @INC, "../sdm/lib";
};

my $build = Module::Build->new(
  module_name => 'Sdm',
  license => 'lgpl',
  dist_version => '0.16',
  dist_abstract => 'Sdm Tools',
  scripts => [ 'bin/sdm-automount.pl' ],
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

$build->create_build_script;
