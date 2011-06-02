#! /usr/bin/perl

use Module::Build;

# With git repos, this should work.
BEGIN {
    push @INC, "../sdm/lib";
};

# On a packaging system, we Build-Require ur-sdm-namespace, so this should work.
use SDM;

my $build = Module::Build->new(
  module_name => 'SDM',
  license => 'lgpl',
  dist_version => '0.05',
  dist_abstract => 'Modules for service management',
  etc_files => { 'etc/sdm-web-app.conf' => 'etc/sdm-web-app.conf' },
  install_path => { 'etc' => '/etc/init' },
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

$build->add_build_element('etc');
$build->add_build_element('psgi');
$build->create_build_script;

