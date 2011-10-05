package Sub::Spec::HTTP::Server::Command;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.08'; # VERSION

sub handle_list_subs {
    my ($env) = @_;
    my $ssu = $env->{"ss.request"}{uri};
    return [400, "SS request URI not specified"] unless $ssu;

    $ssu->list_subs();
}

1;
# ABSTRACT: List subroutines in a module


__END__
=pod

=head1 NAME

Sub::Spec::HTTP::Server::Command - List subroutines in a module

=head1 VERSION

version 0.08

=head1 SYNOPSIS

 # used by Plack::Middleware::SubSpec::HandleCommand

=head1 DESCRIPTION

This module returns list of subroutines within a module. Will return 400 error
if module is not specified in URI.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

