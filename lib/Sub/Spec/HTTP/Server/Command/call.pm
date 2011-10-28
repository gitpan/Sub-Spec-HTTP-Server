package Sub::Spec::HTTP::Server::Command;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.11'; # VERSION

sub handle_call {
    my ($env) = @_;
    my $ssu = $env->{"ss.request"}{uri};
    return [400, "SS request URI not specified"] unless $ssu;
    return [400, "Sub not specified"] unless $ssu->sub;

    $ssu->call(%{$env->{"ss.request"}{args}});
}

1;
# ABSTRACT: Handle 'call' command (call subroutine and return the result)


__END__
=pod

=head1 NAME

Sub::Spec::HTTP::Server::Command - Handle 'call' command (call subroutine and return the result)

=head1 VERSION

version 0.11

=head1 SYNOPSIS

 # used by Plack::Middleware::SubSpec::HandleCommand

=head1 DESCRIPTION

This module uses L<Sub::Spec::Caller> to call the requested subroutine and
format its result. Will return error 500 will be returned if requested output
format is unknown/unallowed.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

