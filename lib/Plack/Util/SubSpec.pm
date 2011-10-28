package Plack::Util::SubSpec;

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(errpage allowed);

our $VERSION = '0.11'; # VERSION

sub errpage {
    my ($msg, $code) = @_;
    $msg .= "\n" unless $msg =~ /\n\z/;
    $code //= 400;
    $msg = "$code - $msg";
    $log->tracef("Sending errpage %s - %s", $code, $msg);
    [$code,
     ["Content-Type" => "text/plain", "Content-Length" => length($msg)],
     [$msg]];
}

sub allowed {
    my ($value, $pred) = @_;
    if (ref($pred) eq 'ARRAY') {
        return $value ~~ @$pred;
    } else {
        return $value =~ /$pred/;
    }
}

1;

__END__
=pod

=head1 NAME

Plack::Util::SubSpec

=head1 VERSION

version 0.11

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

