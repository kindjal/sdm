#! /usr/bin/perl

use Config;
use Module::Build;

# With git repos, this should work.
BEGIN {
    unshift @INC, "$ENV{PWD}/blib/lib";
    push @INC, "../sdm/lib";
};

my $class = Module::Build->subclass (
    class => 'Pod::Builder',
    code => <<'EOS',

      sub ACTION_clean {
        # FIXME: is this safe?
        use File::Path qw/rmtree/;
        rmtree "./_build";
        rmtree "./blib";
        rmtree "./cmd-bindoc";
        unlink "./Build";
        unlink "./MYMETA.yml";
      }

      sub ACTION_cmd_docs {
        use File::Copy qw/copy/;
        $ENV{ANSI_COLORS_DISABLED} = 1;
        eval {
          local @INC = @INC;
          unshift @INC, 'blib/lib';
          die $@ if $@;
          eval "use Sdm::Service";
          die $@ if $@;

          foreach my $exec ('sdm') {
            UR::Namespace::Command::Update::Doc->execute(
                class_name => 'Sdm::Service',
                targets => [ 'Sdm::Service::Lsofc::Command' ],
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
        #$self->depends_on('cmd_docs');
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
  module_name => 'Sdm',
  license => 'lgpl',
  dist_version => '0.17',
  dist_abstract => 'Modules for service management',
  build_requires => {
    'Module::Build' => '',
    'UR' => '0.31',
  },
  requires => {
    'UR' => '0.31',
  },
  bindoc_dirs => ['cmd-bindoc'],
);

$build->add_build_element('psgi');
$build->add_build_element('schema');
$build->create_build_script;

