package Plack::Middleware::SubSpec::Authz::ACL;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(acl acl_file autoreload_acl_file);

use Plack::Util::SubSpec qw(errpage);

our $VERSION = '0.12'; # VERSION

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
# ABSTRACT: Authorize client using access-control list


=pod

=head1 NAME

Plack::Middleware::SubSpec::Authz::ACL - Authorize client using access-control list

=head1 VERSION

version 0.12

=head1 SYNOPSIS

 # In app.psgi
 use Plack::Builder;

 builder {
    enable "SubSpec::Authz::ACL";
 };

=head1 DESCRIPTION

This middleware authorizes clients using access-control list (ACL). ACL can be
specified in the 'acl' configuration or from a file ('acl_file').

=head1 CONFIGURATION

=over 4

=item * acl => ARRAY

=item * acl_file => STR

=item * autoreload_acl_file => BOOL (default 0)

=back

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

