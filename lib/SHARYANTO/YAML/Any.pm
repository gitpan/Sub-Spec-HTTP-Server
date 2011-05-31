package SHARYANTO::YAML::Any;
# ABSTRACT: Pick a YAML implementation and use it.

# NOTE: temporary namespace, will eventually be refactored, tidied up, and sent
# to a more proper namespace.

use 5.010;
use strict;
use Exporter ();

our @ISA       = qw(Exporter);
our @EXPORT    = qw(Dump Load);
our @EXPORT_OK = qw(DumpFile LoadFile);

our $VERSION   = '0.72';

use YAML::Syck;
$YAML::Syck::ImplicitTyping = 1;

1;


=pod

=head1 NAME

SHARYANTO::YAML::Any - Pick a YAML implementation and use it.

=head1 VERSION

version 0.04

=for Pod::Coverage .*

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

