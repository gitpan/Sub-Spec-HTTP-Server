package Sub::Spec::HTTP::Server::Command;

use 5.010;
use strict;
use warnings;

use Sub::Spec::To::Text::Usage qw(spec_to_usage);

our $VERSION = '0.08'; # VERSION

sub handle_usage {
    my ($env) = @_;
    my $ssu = $env->{"ss.request"}{uri};
    return [400, "SS request URI not specified"] unless $ssu;

    my $spec = $ssu->spec();
    spec_to_usage(spec => $spec);
}

1;
# ABSTRACT: Return function usage information


__END__
=pod

=head1 NAME

Sub::Spec::HTTP::Server::Command - Return function usage information

=head1 VERSION

version 0.08

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

