#! /usr/bin/perl

use Config;
use Module::Build;

# With git repos, this should work.
BEGIN {
    unshift @INC, "$ENV{PWD}/blib/lib";
    push @INC, "../sdm/lib";
};

# On a packaging system, we Build-Require ur-sdm-namespace, so this should work.
use SDM;

my $class = Module::Build->subclass (
    class => 'Pod::Builder',
    code => <<'EOS',

      sub ACTION_cmd_docs {
        use File::Copy qw/copy/;
        $ENV{ANSI_COLORS_DISABLED} = 1;
        eval {
          local @INC = @INC;
          unshift @INC, 'blib/lib';
          die $@ if $@;
          eval "use SDM::Service";
          die $@ if $@;

          foreach my $exec ('sdm') {
            UR::Namespace::Command::Update::Doc->execute(
                class_name => 'SDM::Service',
                targets => [ 'SDM::Service::Lsofc::Command' ],
                executable_name => $exec,
                output_path => 'cmd-bindoc',
                output_format => 'pod',
            );
          }
        };
        die "failed to extract pod: $!: $@" if ($@);
      }

      sub ACTION_docs {
        my $self = shift;
        $self->depends_on('code');
        $self->depends_on('cmd_docs');
        $self->depends_on('manpages', 'html');
      }

      sub man1page_name {
        my ($self, $file) = @_;
        $file =~ s/.pod$//;
        return $self->SUPER::man1page_name($file);
      }

EOS
);

my $build = $class->new(
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
  bindoc_dirs => ['cmd-bindoc'],
);

$build->add_build_element('etc');
$build->add_build_element('psgi');
$build->add_build_element('schema');
$build->create_build_script;

