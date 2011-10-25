package Sub::Spec::HTTP::Server::Command;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.09'; # VERSION

sub handle_spec {
    my ($env) = @_;
    my $ssu = $env->{"ss.request"}{uri};
    return [400, "SS request URI not specified"] unless $ssu;

    [200, "OK", $ssu->spec()];
}

1;
# ABSTRACT: Return subroutine spec


__END__
=pod

=head1 NAME

Sub::Spec::HTTP::Server::Command - Return subroutine spec

=head1 VERSION

version 0.09

=head1 SYNOPSIS

 # used by Plack::Middleware::SubSpec::HandleCommand

=head1 DESCRIPTION

This module returns subroutine's spec. Will return 400 error if module or sub is
not specified in URI.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

