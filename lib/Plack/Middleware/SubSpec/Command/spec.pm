package Plack::Middleware::SubSpec::Command::spec;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware);
#use Plack::Util::Accessor qw();

use Plack::Util::SubSpec qw(errpage);

our $VERSION = '0.06'; # VERSION

sub prepare_app {
    my $self = shift;
    die "Not yet implemented";
}

sub call {
    my ($self, $env) = @_;

    # continue to app
    $self->app->($env);
}

1;
# ABSTRACT: Show a subroutine's spec


=pod

=head1 NAME

Plack::Middleware::SubSpec::Command::spec - Show a subroutine's spec

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 # In app.psgi
 use Plack::Builder;

 builder {
    enable "SubSpec::Command::spec";
 };

=head1 DESCRIPTION

This middleware executes the 'spec' command.

=head1 CONFIGURATION

=over 4

=back

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
