
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
  'dist_abstract' => 'Serve subroutine calls via HTTP/HTTPS',
  'dist_author' => [
    'Steven Haryanto <stevenharyanto@gmail.com>'
  ],
  'dist_name' => 'Sub-Spec-HTTP-Server',
  'dist_version' => '0.01',
  'license' => 'perl',
  'module_name' => 'Sub::Spec::HTTP::Server',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'CGI::Lite' => '0',
    'Capture::Tiny' => '0',
    'HTTP::Daemon' => '0',
    'HTTP::Daemon::SSL' => '0',
    'HTTP::Parser' => '0',
    'IO::Handle::Record' => '0',
    'JSON' => '0',
    'Log::Any' => '0',
    'Log::Any::Adapter' => '0',
    'Log::Any::Adapter::Callback' => '0',
    'Moo' => '0',
    'PHP::Serialization' => '0',
    'Sub::Spec' => '0.13',
    'Sub::Spec::Caller' => '0',
    'Sub::Spec::CmdLine' => '0',
    'Test::More' => '0.96',
    'Time::HiRes' => '0',
    'YAML::Syck' => '0',
    'perl' => '5.010000'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
