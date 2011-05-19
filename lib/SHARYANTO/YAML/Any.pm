package SHARYANTO::YAML::Any;
BEGIN {
  $SHARYANTO::YAML::Any::VERSION = '0.01';
}
BEGIN {
  $SHARYANTO::YAML::Any::VERSION = '0.72';
}
# ABSTRACT: SHARYANTO::YAML::Any - Pick a YAML implementation and use it.

use 5.010;
use strict;
use Exporter ();

our @ISA       = qw(Exporter);
our @EXPORT    = qw(Dump Load);
our @EXPORT_OK = qw(DumpFile LoadFile);

use YAML::Syck;
$YAML::Syck::ImplicitTyping = 1;

1;

__END__
=pod

=head1 NAME

SHARYANTO::YAML::Any - SHARYANTO::YAML::Any - Pick a YAML implementation and use it.

=head1 VERSION

version 0.01

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

