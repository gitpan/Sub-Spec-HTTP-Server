package Sub::Spec::HTTP::Server::Command;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.12'; # VERSION

sub handle_list_mods {
    die "Not yet implemented";
}

1;
# ABSTRACT: List available modules


__END__
=pod

=head1 NAME

Sub::Spec::HTTP::Server::Command - List available modules

=head1 VERSION

version 0.12

=head1 SYNOPSIS

 # used by Plack::Middleware::SubSpec::HandleCommand

=head1 DESCRIPTION

This module returns list of available modules.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

