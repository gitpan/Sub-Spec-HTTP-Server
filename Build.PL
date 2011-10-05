
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'PSGI application to serve remote (HTTP) subroutine call requests',
  'dist_author' => [
    'Steven Haryanto <stevenharyanto@gmail.com>'
  ],
  'dist_name' => 'Sub-Spec-HTTP-Server',
  'dist_version' => '0.08',
  'license' => 'perl',
  'module_name' => 'Sub::Spec::HTTP::Server',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Data::Format::Pretty' => '0',
    'Data::Format::Pretty::HTML' => '0',
    'Data::Format::Pretty::JSON' => '0',
    'Data::Format::Pretty::PHPSerialization' => '0',
    'Data::Format::Pretty::YAML' => '0',
    'Data::Rmap' => '0',
    'Log::Any::Adapter' => '0',
    'Log::Any::Adapter::Callback' => '0',
    'Plack' => '0',
    'Sub::Spec' => '1.0.1',
    'Sub::Spec::GetArgs::Array' => '0',
    'Sub::Spec::HTTP' => '1.0.1',
    'Sub::Spec::To::Text::Usage' => '0',
    'Sub::Spec::URI' => '0',
    'Sub::Spec::URI::http' => '0',
    'Test::More' => '0.96',
    'URI::Escape' => '0',
    'YAML::Syck' => '0',
    'perl' => '5.010000'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
