#!/usr/bin/perl
# Use local perl, not some perl on an application server,
# because a build server needs to be sure that this module
# can be packaged in a "clean room" environment.

use Module::Build;

my $class = Module::Build->subclass (
  class => 'Pod::Builder',
  code => q{
    sub ACTION_clean {
      use File::Path qw/rmtree/;
      rmtree "./_build";
      rmtree "./blib";
      unlink "./Build";
      unlink "./MYMETA.yml";
    }
  }
);

my $build = $class->new(
  module_name => 'System',
  license => 'lgpl',
  dist_version => '0.01',
  dist_abstract => 'Modules for system management',
  build_requires => {
    'Module::Build' => '',
    'UR' => '0.28',
  },
  requires => {
    'UR' => '0.28',
  },
);

$build->add_build_element('sqlite3n-schema');
$build->create_build_script;
