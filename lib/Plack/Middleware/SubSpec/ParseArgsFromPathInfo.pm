package Plack::Middleware::SubSpec::ParseArgsFromPathInfo;

use 5.010;
use strict;
use warnings;

use parent qw(Plack::Middleware);
#use Plack::Util::Accessor qw();

use Plack::Util::SubSpec qw(errpage);
use Sub::Spec::GetArgs::Array qw(get_args_from_array);

our $VERSION = '0.06'; # VERSION

#sub prepare_app {
#    my $self = shift;
#}

sub call {
    my ($self, $env) = @_;

    my $argv = $env->{"ss.request.argv"};
    my $spec = $env->{"ss.spec"};

    if ($argv && $spec) {
        my $res = get_args_from_array(array=>$argv, spec=>$spec);
        return errpage("Can't parse arguments from path info: $res->[1]",
                       $res->[0]) unless $res->[0] == 200;
        $env->{'ss.request.args'} //= {};
        for my $k (keys %{$res->[2]}) {
            $env->{'ss.request.args'}{$k} = $res->[2]{$k};
        }
    }

    # continue to app
    $self->app->($env);
}

1;
# ABSTRACT: Parse sub arguments from path info


__END__
=pod

=head1 NAME

Plack::Middleware::SubSpec::ParseArgsFromPathInfo - Parse sub arguments from path info

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 # in your app.psgi
 use Plack::Builder;

 builder {
     enable "SubSpec::ParseArgsFromPathInfo";
 };

=head1 DESCRIPTION

This middleware parses sub argument from path info, using
L<Sub::Spec::GetArgs::Array>. It should be enabled after SubSpec::GetSpec
middleware (and thus separated from SubSpec::ParseRequest) because parsing
positional arguments requires that we have sub spec first.

=head1 SEE ALSO

L<Plack::Middleware::SubSpec::ParseRequest>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

