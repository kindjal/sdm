#! /usr/bin/perl

use Module::Build;

my $build = Module::Build->new(
  module_name => 'System',
  license => 'lgpl',
  dist_version => '0.01',
  dist_abstract => 'Modules for system management',
  scripts => [ 'bin/system' ],
  etc_files => { 'etc/system-web-app.conf' => 'etc/system-web-app.conf' },
  install_path => { 'etc' => '/etc/init' },
  build_requires => {
    'Module::Build' => '',
    'UR' => '0.29',
  },
  requires => {
    'UR' => '0.29',
  },
);

$build->add_build_element('etc');
$build->add_build_element('psgi');
$build->add_build_element('sqlite3n-schema');
$build->create_build_script;
