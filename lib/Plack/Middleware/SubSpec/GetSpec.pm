package Plack::Middleware::SubSpec::GetSpec;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware);
#use Plack::Util::Accessor qw();

use Plack::Util::SubSpec qw(errpage);

our $VERSION = '0.06'; # VERSION

#sub prepare_app {
#    my $self = shift;
#}

sub call {
    my ($self, $env) = @_;

    my $module = $env->{'ss.request.module'};
    my $sub    = $env->{'ss.request.sub'};
    if ($module && $sub) {
        my $spec     = $module . "::SPEC";
        no strict 'refs';
        my $sub_spec = ${$spec}{$sub};
        return errpage("Can't find sub spec for $module\::$sub", 500)
            unless $sub_spec;
        $env->{'ss.spec'} = $sub_spec;
    }

    # continue to app
    $self->app->($env);
}

1;
# ABSTRACT: Get sub spec


__END__
=pod

=head1 NAME

Plack::Middleware::SubSpec::GetSpec - Get sub spec

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 # in your app.psgi
 use Plack::Builder;

 builder {
     enable "SubSpec::GetSpec";
 };

=head1 DESCRIPTION

This middleware gets sub spec from %SPEC package variable, and puts it to
$env->{'ss.spec'}. Will do nothing if $env->{'ss.request.module'} or
$env->{'ss.request.sub'} is not set. Should be enabled after SubSpec::LoadModule
middleware.

=head1 CONFIGURATIONS

=over 4

=back

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

