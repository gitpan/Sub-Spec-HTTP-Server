package Sub::Spec::HTTP::Server::Command;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.10'; # VERSION

sub handle_about {
    my ($env) = @_;
    my $ssreq = $env->{"ss.request"};

    my $ssu = $ssreq->{uri};
    return [200, "OK", {
        uri     => ($ssu ? $ssu->{_uri} : undef),
        module  => ($ssu ? $ssu->module : undef),
        sub     => ($ssu ? $ssu->sub    : undef),
        args    => ($ssu ? $ssu->args   : undef),
    }];
}

1;
# ABSTRACT: Return information about the server and request


__END__
=pod

=head1 NAME

Sub::Spec::HTTP::Server::Command - Return information about the server and request

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 # used by Plack::Middleware::SubSpec::HandleCommand

=head1 DESCRIPTION

This command returns a hashref containing information about the server and
request, e.g.: 'module', 'sub', 'args'

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

