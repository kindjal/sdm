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
  dist_abstract => 'Modules for service management',
  scripts => [ 'bin/system' ],
  etc_files => { 'etc/system-web-app.conf' => 'etc/system-web-app.conf' },
  install_path => { 'etc' => '/etc/init' },
  build_requires => {
    'Module::Build' => '',
    'UR' => '0.30',
    'System' => '',
  },
  requires => {
    'UR' => '0.30',
    'System' => '',
  },
);

$build->add_build_element('etc');
$build->add_build_element('psgi');
$build->create_build_script;

