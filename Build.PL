
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
  'dist_version' => '0.06',
  'license' => 'perl',
  'module_name' => 'Sub::Spec::HTTP::Server',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Data::Format::Pretty' => '0',
    'Data::Format::Pretty::JSON' => '0',
    'Data::Format::Pretty::PHP' => '0',
    'Data::Format::Pretty::YAML' => '0',
    'Log::Any::Adapter' => '0',
    'Log::Any::Adapter::Callback' => '0',
    'Module::List' => '0',
    'Plack' => '0',
    'Sub::Spec' => '0.14',
    'Sub::Spec::Caller' => '0',
    'Sub::Spec::GetArgs::Array' => '0',
    'Test::More' => '0.96',
    'URI::Escape' => '0',
    'YAML::Syck' => '0',
    'perl' => '5.010000'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
