package Plack::Middleware::SubSpec::LimitRate;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware);
#use Plack::Util::Accessor qw();

use Plack::Util::SubSpec qw(errpage);

our $VERSION = '0.10'; # VERSION

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
# ABSTRACT: Limit access rate


=pod

=head1 NAME

Plack::Middleware::SubSpec::LimitRate - Limit access rate

=head1 VERSION

version 0.10

=head1 SYNOPSIS

 # In app.psgi
 use Plack::Builder;

 builder {
    enable "SubSpec::LimitRate";
 };

=head1 DESCRIPTION

This middleware limits access rate. Not yet implemented.

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

